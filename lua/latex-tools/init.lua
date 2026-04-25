-- lua/latex-tools/init.lua
-- Main entry point for latex-tools.nvim
-- Call require('latex-tools').setup() to activate the plugin.
local M = {}

local defaults = {
  snippets = {
    enabled = true,
    -- Filetypes to register snippets into.
    -- Default keeps backward compatibility; Markdown-first users can set { 'markdown' }.
    filetypes = { 'markdown', 'tex' },
    triggers = {
      inline_math = 'mk',
      display_math = 'dm',
      begin_env = 'beg',
      matrix_column = ',,',
    },
    -- Set any key to false to omit that snippet group (matrices = dynamic matrix regTrig, `,,`, `&=`; see README).
    categories = {
      greek_letters = true,
      operators = true,
      symbols = true,
      arrows = true,
      sets_logic = true,
      decorators = true,
      integrals_derivatives = true,
      physics = true,
      chemistry = true,
      matrices = true,
      environments = true,
      brackets = true,
      sequences_series = true,
      trig_functions = true,
    },
    -- Remap trigger strings for built-in snippets.
    -- Key: existing trigger string (exact, or raw Lua pattern for regTrig snippets), e.g. dynamic matrix `'(%d+)%*(%d+)([bBpvV])mat'`.
    -- Value: fields to replace — only trig/wordTrig/regTrig; body/nodes cannot change.
    -- Does not apply to snippets in `extra`.
    overrides = {},

    -- Remove built-in snippets by trigger string. Does not apply to `extra`.
    disable = {},

    -- Raw LuaSnip snippet objects appended after built-in snippets.
    extra = {},
  },
  visual_wrappers = {
    enabled = true,
    keymaps = {
      underbrace = '<leader>lu',
      overbrace  = '<leader>lo',
      cancel     = '<leader>lc',
      cancelto   = '<leader>lk',
      underset   = '<leader>lb',
    },
  },
  matrix = {
    enabled = true,
    enter_inserts_row_sep = true,
    envs = {
      'matrix', 'pmatrix', 'bmatrix', 'Bmatrix',
      'vmatrix', 'Vmatrix', 'smallmatrix',
      'array', 'align', 'align*', 'aligned',
      'cases', 'split', 'gather', 'gather*',
      'gathered', 'eqnarray', 'eqnarray*',
      'multline', 'multline*',
    },
  },
  context = {
    use_treesitter = true,
  },
}

--- Setup latex-tools.nvim.
--- @param opts table|nil User configuration (merged with defaults via tbl_deep_extend)
function M.setup(opts)
  local config = vim.tbl_deep_extend('force', defaults, opts or {})
  M.config = config

  if config.snippets.enabled then
    require('latex-tools.snippets').register(config)
  end

  if config.visual_wrappers.enabled then
    require('latex-tools.visual_wrappers').setup(config)
  end

  if config.matrix.enabled then
    require('latex-tools.matrix').setup(config)
  end
end

-- Export submodules for external integration
-- e.g. autolist.lua can call require('latex-tools').matrix.handle_enter()
M.context     = require 'latex-tools.context'
M.math_parser = require 'latex-tools.math_parser'
M.matrix      = require 'latex-tools.matrix'

return M
