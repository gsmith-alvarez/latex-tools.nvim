-- tests/minimal_init.lua
-- Bootstrap: create an isolated runtimepath, load MiniTest.
local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h:h')

-- Avoid pulling in user config/after/ftplugin from default runtimepath.
-- Keep only Vim runtime + this plugin + test deps.
local vimruntime = os.getenv('VIMRUNTIME')
vim.opt.rtp = {}
if vimruntime and vimruntime ~= '' then
  vim.opt.rtp:append(vimruntime)
end
vim.opt.rtp:append(plugin_root)

-- Disable runtime ftplugins/indent (can trigger Treesitter parser startup).
vim.cmd('filetype plugin indent off')

-- Load MiniTest. Prefer user's local install, but fall back to vendored copy
-- so tests can run in clean environments.
-- Avoid shada/swap writes outside workspace (sandbox-friendly)
vim.opt.shadafile = 'NONE'
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.undofile = false
vim.opt.updatecount = 0

local mini_path = vim.fn.expand('~/.local/share/nvim/lazy/mini.nvim')
if vim.uv.fs_stat(mini_path) then
  vim.opt.rtp:prepend(mini_path)
else
  vim.opt.rtp:prepend(plugin_root .. '/tests/vendor/mini.nvim')
end

local MiniTest = require('mini.test')
MiniTest.setup({
  execute = {
    reporter = MiniTest.gen_reporter.stdout({ group_depth = 1 }),
  },
})
