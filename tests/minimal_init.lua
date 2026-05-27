-- Headless test bootstrap: repo minimal_init + MiniTest.
local src = debug.getinfo(1, 'S').source
if src:sub(1, 1) == '@' then
  src = src:sub(2)
end
local root = vim.fn.fnamemodify(src, ':p:h:h')

local minimal, err = loadfile(root .. '/minimal_init.lua')
if not minimal then
  error(('tests/minimal_init: cannot load %s/minimal_init.lua: %s'):format(root, err or 'unknown'))
end
minimal()

vim.cmd('filetype plugin indent off')

vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.undofile = false
vim.opt.updatecount = 0

local pack, pack_err = loadfile(root .. '/pack_deps.lua')
if not pack then
  error(('tests/minimal_init: cannot load pack_deps.lua: %s'):format(pack_err or 'unknown'))
end
pack = pack()

if not pack.prepend_opt('mini.nvim') then
  vim.opt.rtp:prepend(root .. '/tests/vendor/mini.nvim')
end

require('mini.test').setup({
  execute = {
    reporter = require('mini.test').gen_reporter.stdout({ group_depth = 1 }),
  },
})
