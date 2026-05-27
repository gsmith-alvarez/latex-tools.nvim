-- Minimal Neovim config: latex-tools.nvim on &rtp only.
--
--   nvim --clean -u minimal_init.lua
--   :source dev.vim
local src = debug.getinfo(1, 'S').source
if src:sub(1, 1) == '@' then
  src = src:sub(2)
end
local plugin_root = vim.fn.fnamemodify(src, ':p:h')

local vimruntime = os.getenv('VIMRUNTIME')
vim.opt.rtp = {}
if vimruntime and vimruntime ~= '' then
  vim.opt.rtp:append(vimruntime)
end
vim.opt.rtp:append(plugin_root)

vim.opt.shadafile = 'NONE'
vim.opt.swapfile = false
-- Interactive hint: :source dev.vim
