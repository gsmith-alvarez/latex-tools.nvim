-- lua/latex-tools/auto_brackets.lua
-- Auto-enlarge enclosing ( or [ with \left/\right when a \frac, \int or \sum
-- snippet is triggered inside them.
local M = {}

local CLOSE_OF  = { ['('] = ')',       ['['] = ']'       }
local LEFT_CMD  = { ['('] = '\\left(', ['['] = '\\left[' }
local RIGHT_CMD = { ['('] = '\\right)', ['['] = '\\right]' }

--- Find the innermost unmatched ( or [ in `text`, scanning up to (not including)
--- 1-indexed position `limit`.
--- Returns (open_char, 1-indexed-position) or (nil, nil).
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

--- LuaSnip snippet callback for the pre_expand event.
---
--- Attach as:
---   callbacks = { [-1] = { [events.pre_expand] = M.enlarge_at_trigger_pos } }
---
--- event_args.expand_pos = {row_1idx, col_0idx} — cursor position at trigger time.
---
--- The enlargement is deferred via vim.schedule so it runs after the snippet
--- text has been inserted into the buffer.
---
--- Conditions: both the open bracket and its matching close must exist on the
--- same line. Does nothing if the bracket is already preceded by \left.
function M.enlarge_at_trigger_pos(_, event_args)
  local expand_pos = event_args and event_args.expand_pos
  if not expand_pos or not expand_pos[1] then return end

  -- expand_pos from nvim_win_get_cursor: row is 1-indexed, col is 0-indexed.
  local row_0 = expand_pos[1] - 1   -- convert to 0-indexed for nvim_buf_get_lines
  local col_1 = expand_pos[2] + 1   -- convert to 1-indexed for find_open limit

  vim.schedule(function()
    -- Snippet is now in the buffer. Characters before the trigger position are
    -- unchanged, so find_open correctly finds the bracket. Characters after may
    -- have shifted (trigger replaced by snippet text), but find_close works on
    -- the current line which has the correct close bracket position.
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, row_0, row_0 + 1, false)
    if not lines[1] then return end
    local line = lines[1]

    local open_char, open_pos = find_open(line, col_1)
    if not open_char then return end

    local close_pos = find_close(line, open_char, open_pos + 1)
    if not close_pos then return end

    -- Skip if already enlarged
    if line:sub(open_pos - 5, open_pos - 1) == '\\left' then return end

    -- Replace close bracket first (further right, so open_pos stays valid)
    vim.api.nvim_buf_set_text(bufnr, row_0, close_pos - 1, row_0, close_pos, { RIGHT_CMD[open_char] })
    -- Replace open bracket
    vim.api.nvim_buf_set_text(bufnr, row_0, open_pos - 1, row_0, open_pos, { LEFT_CMD[open_char] })
  end)
end

return M
