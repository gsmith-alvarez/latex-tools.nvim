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
--- For tex/latex filetypes: always returns true (entire file is math-capable).
--- For markdown filetypes:  tries treesitter, falls back to line scanner.
--- For all other filetypes: returns false.
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

    -- \text{} / \textbf{} etc. explicitly escape back to text mode
    if ntype == 'text_mode' then return false end

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

  -- Truncate last line to cursor position (col is 0-indexed; sub is 1-indexed)
  lines[#lines] = lines[#lines]:sub(1, col + 1)

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

--- Try treesitter first; fall back to line scanner on nil result.
--- @return boolean
function M._check_mathzone_markdown()
  local ts_result = M._check_mathzone_treesitter()
  if ts_result ~= nil then return ts_result end
  return M._check_mathzone_fallback()
end

-- =============================================================================
-- INTERNAL: MATRIX ENV SCANNER
-- =============================================================================

--- Scan all text from buffer start up to (and including) cursor position,
--- building a stack of open \begin{env}...\end{env} pairs.
--- Returns the innermost open environment if it is a known matrix env.
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
