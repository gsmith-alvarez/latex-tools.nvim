-- [[ VISUAL WRAPPERS: lua/latex-tools/visual_wrappers.lua ]]
-- =============================================================================
-- Purpose: Visual-mode LaTeX annotation wrappers for math zones.
-- Domain:  Scientific Notetaking / LaTeX Editing
--
-- Architecture: Provides visual-mode keymaps that wrap selected text with
--               common LaTeX annotation commands (underbrace, overbrace,
--               cancel, cancelto, underset). Only active in math zones
--               (markdown math or tex/latex filetypes).
--
-- Philosophy: "Frictionless Annotation." Annotating, canceling, or decorating
--             mathematical expressions should be as fast as selecting and
--             pressing a key. No menus, no commands to remember.
--
-- Usage (default keymaps):
--   In visual mode, select math text, then press:
--     <leader>nu  →  \underbrace{<selection>}_{<cursor>}
--     <leader>no  →  \overbrace{<selection>}^{<cursor>}
--     <leader>nc  →  \cancel{<selection>}
--     <leader>nk  →  \cancelto{<cursor>}{<selection>}
--     <leader>nb  →  \underset{<cursor>}{<selection>}
--
-- Maintenance:
-- 1. Requires latex-tools.context for is_in_mathzone() detection.
-- 2. Keymaps configured via config.visual_wrappers.keymaps in M.setup().
-- =============================================================================

local M = {}
local context = require 'latex-tools.context'

-- =============================================================================
-- CONTEXT DETECTION
-- =============================================================================

--- Check if cursor is in a math zone (uses context.is_in_mathzone or filetype fallback)
---@return boolean
local function in_math_context()
  local ft = vim.bo.filetype
  if ft == 'tex' or ft == 'latex' then return true end
  if not context.is_in_mathzone then return false end
  return context.is_in_mathzone()
end

-- =============================================================================
-- VISUAL SELECTION HELPERS
-- =============================================================================

--- Get the current visual selection text and range
--- Must be called after exiting visual mode (marks are set)
---@return table|nil { from = {row, col}, to = {row, col}, text = string }
local function get_visual_selection()
  local s_pos = vim.fn.getpos "'<"
  local e_pos = vim.fn.getpos "'>"

  local s_row, s_col = s_pos[2], s_pos[3]
  local e_row, e_col = e_pos[2], e_pos[3]

  -- Handle visual mode end column (can be very large for line selection)
  local e_line = vim.api.nvim_buf_get_lines(0, e_row - 1, e_row, false)[1] or ''
  if e_col > #e_line then
    e_col = #e_line
  end

  -- Convert to 0-indexed for nvim_buf_get_text
  local lines = vim.api.nvim_buf_get_text(0, s_row - 1, s_col - 1, e_row - 1, e_col, {})

  return {
    from = { s_row - 1, s_col - 1 }, -- 0-indexed
    to = { e_row - 1, e_col }, -- 0-indexed, exclusive end
    text = table.concat(lines, '\n'),
  }
end

--- Replace the visual selection with new text
---@param range table { from = {row, col}, to = {row, col} }
---@param replacement string
local function replace_selection(range, replacement)
  local lines = vim.split(replacement, '\n', { plain = true })
  vim.api.nvim_buf_set_text(0, range.from[1], range.from[2], range.to[1], range.to[2], lines)
end

--- Place cursor at a specific position after replacement
---@param row number 0-indexed row
---@param col number 0-indexed column
local function place_cursor(row, col)
  vim.api.nvim_win_set_cursor(0, { row + 1, col })
end

-- =============================================================================
-- WRAPPER FUNCTIONS
-- =============================================================================

--- Generic wrapper that surrounds selection with LaTeX command
--- Handles cursor placement for empty braces to fill
---@param before string Text before selection (e.g., "\\underbrace{")
---@param after string Text after selection (e.g., "}_{}")
---@param cursor_offset_from_end number|nil Offset from end to place cursor (for empty braces)
local function wrap_visual(before, after, cursor_offset_from_end)
  if not in_math_context() then
    vim.notify('Not in math zone', vim.log.levels.WARN)
    return
  end

  local sel = get_visual_selection()
  if not sel then
    vim.notify('No selection', vim.log.levels.WARN)
    return
  end

  local replacement = before .. sel.text .. after
  replace_selection(sel, replacement)

  -- Calculate cursor position
  if cursor_offset_from_end and cursor_offset_from_end > 0 then
    -- Note: cursor placement assumes single-line selection; multi-line selections
    -- will place cursor at the end of the first line (known limitation).
    -- Place cursor inside the empty braces at the end
    local new_text_end_row = sel.from[1]
    local new_text_end_col = sel.from[2] + #replacement - cursor_offset_from_end
    place_cursor(new_text_end_row, new_text_end_col)
    -- Enter insert mode
    vim.cmd 'startinsert'
  end
end

--- Wrap selection with \underbrace{...}_{<cursor>}
function M.underbrace()
  -- \underbrace{SELECTION}_{} - cursor goes in the empty {}
  wrap_visual('\\underbrace{', '}_{Annotation}', 1)
end

--- Wrap selection with \overbrace{...}^{<cursor>}
function M.overbrace()
  -- \overbrace{SELECTION}^{} - cursor goes in the empty {}
  wrap_visual('\\overbrace{', '}^{Annotation}', 1)
end

--- Wrap selection with \cancel{...}
function M.cancel()
  -- \cancel{SELECTION} - no cursor placement needed
  wrap_visual('\\cancel{', '}', nil)
end

--- Wrap selection with \cancelto{<cursor>}{...}
function M.cancelto()
  -- \cancelto{}{SELECTION} - cursor goes in the first empty {}
  if not in_math_context() then
    vim.notify('Not in math zone', vim.log.levels.WARN)
    return
  end

  local sel = get_visual_selection()
  if not sel then
    vim.notify('No selection', vim.log.levels.WARN)
    return
  end

  -- Build: \cancelto{<cursor>}{SELECTION}
  local replacement = '\\cancelto{Target}{' .. sel.text .. '}'
  replace_selection(sel, replacement)

  -- Place cursor inside first {} (after \cancelto{)
  local cursor_col = sel.from[2] + #'\\cancelto{'
  place_cursor(sel.from[1], cursor_col)
  vim.cmd 'startinsert'
end

--- Wrap selection with \underset{<cursor>}{...}
function M.underset()
  -- \underset{}{SELECTION} - cursor goes in the first empty {}
  if not in_math_context() then
    vim.notify('Not in math zone', vim.log.levels.WARN)
    return
  end

  local sel = get_visual_selection()
  if not sel then
    vim.notify('No selection', vim.log.levels.WARN)
    return
  end

  -- Build: \underset{<cursor>}{SELECTION}
  local replacement = '\\underset{Below}{' .. sel.text .. '}'
  replace_selection(sel, replacement)

  -- Place cursor inside first {} (after \underset{)
  local cursor_col = sel.from[2] + #'\\underset{'
  place_cursor(sel.from[1], cursor_col)
  vim.cmd 'startinsert'
end

-- =============================================================================
-- KEYMAP SETUP
-- =============================================================================

--- Setup visual-mode keymaps for math wrappers
--- Keymaps are configured via config.visual_wrappers.keymaps
---@param config table Plugin configuration
function M.setup(config)
  M.config = config

  local keymaps = config.visual_wrappers and config.visual_wrappers.keymaps
  if not keymaps then
    return
  end

  local opts = { noremap = true, silent = true }

  local function bind(key, fn, desc)
    if not key then
      return
    end
    vim.keymap.set('x', key, function()
      -- Exit visual mode to set marks, then call wrapper
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', false)
      vim.schedule(fn)
    end, vim.tbl_extend('force', opts, { desc = desc }))
  end

  bind(keymaps.underbrace, M.underbrace, 'Math: Underbrace selection')
  bind(keymaps.overbrace, M.overbrace, 'Math: Overbrace selection')
  bind(keymaps.cancel, M.cancel, 'Math: Cancel selection')
  bind(keymaps.cancelto, M.cancelto, 'Math: Cancelto selection')
  bind(keymaps.underset, M.underset, 'Math: Underset selection')
end

return M
