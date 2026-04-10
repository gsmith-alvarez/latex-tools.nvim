-- lua/latex-tools/auto_brackets.lua
-- Auto-enlarge enclosing ( or [ with \left/\right when a \frac, \int or \sum
-- snippet is triggered inside them.
local M = {}

local CLOSE_OF  = { ['('] = ')',       ['['] = ']'       }
local LEFT_CMD  = { ['('] = '\\left(', ['['] = '\\left[' }
local RIGHT_CMD = { ['('] = '\\right)', ['['] = '\\right]' }

--- Find the innermost unmatched ( or [ in `text` up to (not including) the
--- 0-indexed column `col_0` (i.e. the snippet start position).
--- Returns (open_char, 1-indexed-position) or (nil, nil).
local function find_open(text, col_0)
  local stack = {}
  for i = 1, math.min(col_0, #text) do
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

--- Find the 1-indexed position of the close bracket that matches `open_char`,
--- scanning `text` forward from position `from` (1-indexed).
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

--- LuaSnip snippet callback: enlarge the nearest enclosing ( or [ around the
--- snippet with \left / \right.
---
--- Attach to a snippet spec as:
---   callbacks = { [-1] = { [events.enter] = M.enlarge_at_snippet_start } }
---
--- Only fires when BOTH the open and a matching close bracket exist on the same
--- line. Does nothing if the bracket is already preceded by \left.
function M.enlarge_at_snippet_start(node)
  -- Capture snippet start position before scheduling (mark may move after schedule)
  local ok, pos = pcall(function() return node.mark:start_raw() end)
  if not ok or not pos then return end

  vim.schedule(function()
    -- Re-read after LuaSnip has finished setting up the snippet
    local ok2, cur_pos = pcall(function() return node.mark:start_raw() end)
    if not ok2 or not cur_pos then return end
    local row_0, col_0 = cur_pos[1], cur_pos[2]

    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, row_0, row_0 + 1, false)
    if not lines[1] then return end
    local line = lines[1]

    local open_char, open_pos = find_open(line, col_0)
    if not open_char then return end

    local close_pos = find_close(line, open_char, open_pos + 1)
    if not close_pos then return end

    -- Skip if the bracket is already enlarged (preceded by \left)
    if line:sub(open_pos - 5, open_pos - 1) == '\\left' then return end

    -- Replace close bracket first — it's to the right, so it does not shift open_pos
    vim.api.nvim_buf_set_text(bufnr, row_0, close_pos - 1, row_0, close_pos, { RIGHT_CMD[open_char] })
    -- Replace open bracket
    vim.api.nvim_buf_set_text(bufnr, row_0, open_pos - 1, row_0, open_pos, { LEFT_CMD[open_char] })
  end)
end

return M
