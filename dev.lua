-- Dev bootstrap (after minimal_init.lua). Loaded by dev.vim via :luafile.
local src = debug.getinfo(1, 'S').source
if src:sub(1, 1) == '@' then
  src = src:sub(2)
end
local root = vim.fn.fnamemodify(src, ':p:h')

local pack, err = loadfile(root .. '/pack_deps.lua')
if not pack then
  error(('dev.lua: cannot load pack_deps.lua: %s'):format(err or 'unknown'))
end
pack = pack()

if not pack.prepend_opt('LuaSnip') then
  vim.notify(
    'LuaSnip not found under pack/core/opt — run :packadd LuaSnip or install the plugin',
    vim.log.levels.WARN
  )
end

require('latex-tools').setup({
  snippets = { register_timing = 'immediate' },
})

print('latex-tools setup() done (snippets: immediate)')
