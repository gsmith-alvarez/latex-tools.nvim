-- tests/minimal_init.lua
-- Bootstrap: add plugin to runtimepath, load MiniTest
local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':h:h')
vim.opt.rtp:prepend(plugin_root)

-- Load MiniTest from dotfiles config (managed by lazy.nvim)
local mini_path = vim.fn.expand('~/.local/share/nvim/lazy/mini.nvim')
vim.opt.rtp:prepend(mini_path)
local MiniTest = require('mini.test')
MiniTest.setup({
  execute = {
    reporter = MiniTest.gen_reporter.stdout({ group_depth = 1 }),
  },
})
