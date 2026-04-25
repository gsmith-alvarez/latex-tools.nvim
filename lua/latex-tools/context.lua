-- lua/latex-tools/context.lua
-- Self-contained math zone and matrix environment detection.
-- No dependency on utils.lua or any dotfiles module.
local M = {}

-- =============================================================================
-- CONSTANTS
-- =============================================================================

--- Treesitter node types that indicate being inside a math zone.
--- Values are boolean true (we only need presence, not kind).
local TS_MATH_NODES = {
  math_environment = true,
  latex_block = true,
  displayed_equation = true,
  inline_formula = true,
  math = true,
  inline_math = true,
  -- Additional names used by various grammar/parser versions
  math_block = true,
  math_span = true,
  dollar_math = true,
  inline_math_env = true,
}

--- Text commands that escape back to text mode inside LaTeX math.
local LATEX_TEXT_CMDS = {
  bf = true, it = true, rm = true, sf = true, tt = true,
  sc = true, sl = true, up = true, md = true, normal = true,
}

--- Matrix/tabular-style environment names.
local MATRIX_ENVS = {
  'matrix',    'pmatrix',   'bmatrix',   'Bmatrix',
  'vmatrix',   'Vmatrix',   'smallmatrix',
  'array',
  'align',     'align*',    'aligned',
  'cases',     'split',
  'gather',    'gather*',   'gathered',
  'eqnarray',  'eqnarray*',
  'multline',  'multline*',
}

-- =============================================================================
-- PUBLIC API
-- =============================================================================

--- Check if cursor is in a math zone.
--- For tex/latex: always returns true (entire file is considered math-capable).
--- Known limitation: \text{...} escapes inside .tex files are not detected;
---   snippets may fire inside \text{} in .tex files.
--- For markdown*: uses Treesitter + fallback line scanner.
--- @return boolean
function M.is_in_mathzone()
  local ft = vim.bo.filetype
  if ft == 'tex' or ft == 'latex' then return true end
  if ft == 'markdown' or ft:match('^markdown') then
    return M._check_mathzone_markdown()
  end
  return false
end

--- Check if cursor is inside a matrix-like LaTeX environment.
--- @return boolean in_matrix
--- @return string|nil env_name  Name of innermost matrix env, or nil
function M.is_in_matrix_env()
  if not M.is_in_mathzone() then return false, nil end
  return M._scan_matrix_env()
end

--- Check if cursor is inside an align-like LaTeX environment.
--- Used for the &= row-separator autosnippet.
--- @return boolean
function M.is_in_align_env()
  if not M.is_in_mathzone() then return false end
  local in_mat, env = M._scan_matrix_env()
  if not in_mat or not env then return false end
  local align_envs = {
    align = true, ['align*'] = true, aligned = true,
    eqnarray = true, ['eqnarray*'] = true,
  }
  return align_envs[env] == true
end

--- Check if cursor is in a fenced code block.
--- Tries snippets.utils.in_code_block() via pcall first (dotfiles integration),
--- then falls back to a simple line scanner.
--- @return boolean
function M.is_in_code_block()
  -- Try dotfiles integration first; only trust an affirmative (true) result.
  -- A false from the dotfiles may mean Treesitter wasn't available, so we
  -- always fall through to our own line scanner when the result is false.
  local ok, snip_utils = pcall(require, 'snippets.utils')
  if ok and type(snip_utils.in_code_block) == 'function' then
    local result = snip_utils.in_code_block()
    if result == true then return true end
  end

  -- Fallback: scan from buffer start to cursor for unmatched ``` fences
  local bufnr = vim.api.nvim_get_current_buf()
  local pos = vim.api.nvim_win_get_cursor(0)
  local row = pos[1] - 1  -- 0-indexed

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, row, false)
  local in_block = false
  for _, line in ipairs(lines) do
    if line:match('^```') then
      in_block = not in_block
    end
  end
  return in_block
end

--- Check if cursor is in plain text (not in a math zone, not in a code block).
--- @return boolean
function M.is_plain_text()
  return not M.is_in_mathzone() and not M.is_in_code_block()
end

-- =============================================================================
-- INTERNAL: TREESITTER PATH
-- =============================================================================

--- Walk TS nodes from cursor upward looking for a math zone.
--- Returns:
---   true  — cursor is in a math node (and not escaped by \text{})
---   false — cursor is explicitly in text mode (\text{} or text_mode node)
---   nil   — treesitter unavailable or no conclusive node found (try fallback)
--- @return boolean|nil
function M._check_mathzone_treesitter()
  local ok_ts, ts = pcall(require, 'vim.treesitter')
  if not ok_ts then return nil end

  local pos = vim.api.nvim_win_get_cursor(0)
  local ok_node, node = pcall(ts.get_node, { pos = { pos[1] - 1, pos[2] } })
  if not ok_node or not node then return nil end

  local bufnr = vim.api.nvim_get_current_buf()

  while node do
    local ntype = node:type()

    -- \text{} / \textbf{} etc. explicitly escape back to text mode.
    -- In .tex/.latex, text_mode is a real \text{} escape inside math — not math.
    -- In markdown, text_mode may be the LaTeX injection root (not an explicit
    -- escape), so we return nil to let the fallback line scanner decide instead
    -- of incorrectly blocking it with false.
    if ntype == 'text_mode' then
      local ft = vim.bo.filetype
      if ft == 'tex' or ft == 'latex' then return false end
      return nil
    end

    -- Some parsers expose \text{...} as generic_command / command nodes
    if ntype == 'generic_command' or ntype == 'command' then
      local ok_txt, text = pcall(vim.treesitter.get_node_text, node, bufnr)
      if ok_txt and text then
        if text:match('^\\text') or text:match('^\\intertext') then
          return false
        end
      end
    end

    if TS_MATH_NODES[ntype] then return true end

    node = node:parent()
  end

  return nil -- no math node found via TS
end

-- =============================================================================
-- INTERNAL: LINE SCANNER FALLBACK
-- =============================================================================

--- Scan lines up to (and including) cursor to count unmatched $ / $$ delimiters.
--- Handles:
---   - \$ escapes (treated as non-delimiter)
---   - `...` inline code spans (masked so $ inside doesn't count)
---   - inline_math resets at each line boundary (markdown $ doesn't span lines)
---   - $$ display math DOES span lines
--- @return boolean
function M._check_mathzone_fallback()
  local bufnr = vim.api.nvim_get_current_buf()
  local pos = vim.api.nvim_win_get_cursor(0)
  local row, col = pos[1] - 1, pos[2]

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, row + 1, false)
  if #lines == 0 then return false end

  -- Truncate last line to just BEFORE the cursor position.
  -- In insert mode the cursor sits on the closing delimiter (e.g. the
  -- closing $ of $...$).  Including that character would toggle the math
  -- state back off, giving a false negative.  Using col (not col+1)
  -- excludes the character at the cursor and scans only text that has
  -- already been typed.
  lines[#lines] = lines[#lines]:sub(1, col)

  local display_math = false
  local inline_math = false

  for _, line in ipairs(lines) do
    -- Inline math does not span lines in standard Markdown
    inline_math = false

    -- Replace \$ with two spaces so it doesn't trip the delimiter scanner
    line = line:gsub('\\%$', '  ')
    -- Mask `...` inline code so $ inside doesn't count
    line = line:gsub('`[^`]*`', function(m) return string.rep(' ', #m) end)

    local idx = 1
    while idx <= #line do
      if line:sub(idx, idx + 1) == '$$' then
        -- $$ toggles display math (only when not inside inline $)
        if not inline_math then
          display_math = not display_math
        end
        idx = idx + 2
      elseif line:sub(idx, idx) == '$' then
        -- $ toggles inline math (only when not inside display $$)
        if not display_math then
          inline_math = not inline_math
        end
        idx = idx + 1
      else
        idx = idx + 1
      end
    end
  end

  return display_math or inline_math
end

-- =============================================================================
-- INTERNAL: MARKDOWN MATH CHECK
-- =============================================================================

--- Try treesitter first; fall back to line scanner unless TS returns true.
--- In markdown, we only trust TS's positive result (true = definitely in math).
--- For nil (inconclusive) OR false (heuristic match like \text{} which can
--- fire on unrelated node text in injected LaTeX), we always defer to the
--- fallback line scanner, which is authoritative for markdown math zones.
--- @return boolean
function M._check_mathzone_markdown()
  local ts_result = M._check_mathzone_treesitter()
  if ts_result == true then return true end
  -- false or nil: fallback is authoritative in markdown
  return M._check_mathzone_fallback()
end

-- =============================================================================
-- INTERNAL: MATRIX ENV SCANNER
-- =============================================================================

--- Scan buffer from start to cursor for open \begin{env} with no matching \end{env}.
--- Known limitation: mismatched \end{env} (wrong env name) is silently discarded,
---   not unwound. May produce wrong results on partially-formed LaTeX.
--- @return boolean in_matrix
--- @return string|nil env_name
function M._scan_matrix_env()
  local bufnr = vim.api.nvim_get_current_buf()
  local pos = vim.api.nvim_win_get_cursor(0)
  local row, col = pos[1], pos[2]

  -- Get lines from start up to (but not past) cursor row (1-indexed row)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, row, false)
  if #lines == 0 then return false, nil end

  -- Truncate the last line to cursor column
  lines[#lines] = lines[#lines]:sub(1, col + 1)

  local text = table.concat(lines, '\n')

  local env_stack = {}
  local search_pos = 1

  while search_pos <= #text do
    local bs, be, benv = text:find('\\begin%s*{([^}]+)}', search_pos)
    local es, ee, eenv = text:find('\\end%s*{([^}]+)}',   search_pos)

    if bs and (not es or bs < es) then
      -- \begin{env} comes first (or \end not found)
      table.insert(env_stack, benv)
      search_pos = be + 1
    elseif es then
      -- \end{env} comes first (or \begin not found)
      if #env_stack > 0 and env_stack[#env_stack] == eenv then
        table.remove(env_stack)
      end
      search_pos = ee + 1
    else
      break
    end
  end

  -- Walk stack from innermost outward; return first matrix env found
  for i = #env_stack, 1, -1 do
    local env = env_stack[i]
    for _, menv in ipairs(MATRIX_ENVS) do
      if env == menv then return true, env end
    end
  end

  return false, nil
end

return M
