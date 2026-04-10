-- lua/latex-tools/auto_brackets.lua
-- Auto-enlarge enclosing ( or [ with \left/\right when a \frac, \int or \sum
-- snippet is triggered inside them.
local M = {}

local CLOSE_OF  = { ['('] = ')',        ['['] = ']'        }
local LEFT_CMD  = { ['('] = '\\left(',  ['['] = '\\left['  }
local RIGHT_CMD = { ['('] = '\\right)', ['['] = '\\right]' }

--- Find the innermost unmatched ( or [ in `text`, scanning 1-indexed positions
--- 1 through (limit - 1). Returns (open_char, 1-indexed-position) or (nil, nil).
local function find_open(text, limit)
  local stack = {}
  for i = 1, math.min(limit - 1, #text) do
    local c = text:sub(i, i)
    if c == '(' or c == '[' then
      stack[#stack + 1] = { c = c, pos = i }
    elseif c == ')' or c == ']' then
      local match = c == ')' and '(' or '['
      for j = #stack, 1, -1 do
        if stack[j].c == match then
          table.remove(stack, j)
          break
        end
      end
    end
  end
  if #stack > 0 then
    local top = stack[#stack]
    return top.c, top.pos
  end
  return nil, nil
end

--- Find the 1-indexed position of the close bracket matching `open_char`,
--- scanning `text` forward from 1-indexed position `from`.
local function find_close(text, open_char, from)
  local close = CLOSE_OF[open_char]
  local depth = 1
  for i = from, #text do
    local c = text:sub(i, i)
    if c == open_char then
      depth = depth + 1
    elseif c == close then
      depth = depth - 1
      if depth == 0 then return i end
    end
  end
  return nil
end

--- LuaSnip snippet callback: enlarge the enclosing ( or [ around the snippet
--- with \left / \right.
---
--- Attach as:
---   callbacks = { [-1] = { [events.enter] = M.enlarge_enclosing } }
---
--- Fires when the snippet has just been expanded and the cursor is sitting on
--- the first insert node. We capture the cursor position immediately, then
--- defer the buffer modification via `vim.schedule` so LuaSnip has time to
--- finish wiring its extmarks.
---
--- Conditions: both the open bracket and its matching close must exist on the
--- same line. Does nothing if the bracket is already preceded by `\left`.
function M.enlarge_enclosing()
  -- Capture cursor position NOW (before scheduling) — it's at the first insert
  -- node of the just-expanded snippet, which is somewhere inside the snippet.
  local cur = vim.api.nvim_win_get_cursor(0)
  local row_0 = cur[1] - 1   -- 1-indexed → 0-indexed
  local col_0 = cur[2]       -- already 0-indexed

  vim.schedule(function()
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, row_0, row_0 + 1, false)
    if not lines[1] then return end
    local line = lines[1]

    -- Scan backward from cursor for the innermost unmatched ( or [.
    -- col_0 + 1 converts 0-indexed column to 1-indexed scan limit.
    local open_char, open_pos = find_open(line, col_0 + 1)
    if not open_char then return end

    -- Scan forward from just after the open bracket for the matching close.
    local close_pos = find_close(line, open_char, open_pos + 1)
    if not close_pos then return end

    -- Skip if already enlarged
    if line:sub(open_pos - 5, open_pos - 1) == '\\left' then return end

    -- Replace close bracket first (further right → does not shift open_pos)
    vim.api.nvim_buf_set_text(bufnr, row_0, close_pos - 1, row_0, close_pos, { RIGHT_CMD[open_char] })
    -- Then replace open bracket
    vim.api.nvim_buf_set_text(bufnr, row_0, open_pos - 1, row_0, open_pos, { LEFT_CMD[open_char] })
  end)
end

return M
