-- lua/latex-tools/health.lua
-- :checkhealth latex-tools
local M = {}

local MIN_Nvim_MINOR = 10

--- @return boolean ok
--- @return string|nil message
local function nvim_version_ok()
  local v = vim.version()
  if not v or type(v.major) ~= 'number' then
    return false, 'could not read vim.version()'
  end
  if v.major > 0 then
    return true, nil
  end
  if v.minor >= MIN_Nvim_MINOR then
    return true, nil
  end
  return false, ('Neovim 0.%d+ required; this is 0.%d.%d'):format(MIN_Nvim_MINOR, v.minor, v.patch or 0)
end

--- Read LuaSnip merged config if available.
--- @return boolean|nil enable_autosnippets nil if unknown
local function luasnip_autosnippets_enabled()
  local ok, session = pcall(require, 'luasnip.session')
  if not ok or type(session) ~= 'table' or type(session.config) ~= 'table' then
    return nil
  end
  local v = session.config.enable_autosnippets
  if type(v) == 'boolean' then
    return v
  end
  return nil
end

function M.check()
  vim.health.start('latex-tools')

  local ok_ver, ver_msg = nvim_version_ok()
  if ok_ver then
    local v = vim.version()
    vim.health.ok(('Neovim %d.%d.%d meets latex-tools requirement (0.%d+).'):format(
      v.major or 0,
      v.minor or 0,
      v.patch or 0,
      MIN_Nvim_MINOR
    ))
  else
    vim.health.error(ver_msg or 'Neovim version check failed.')
  end

  vim.health.start('LuaSnip')
  local ok_ls, ls_or_err = pcall(require, 'luasnip')
  if not ok_ls then
    vim.health.error('LuaSnip is not installed or could not be required (`require("luasnip")` failed).')
    vim.health.info('Add L3MON4D3/LuaSnip as a dependency and load it before `require("latex-tools").setup()`.')
  else
    vim.health.ok('LuaSnip is loadable.')
    local auto = luasnip_autosnippets_enabled()
    if auto == true then
      vim.health.ok('LuaSnip `enable_autosnippets` is on (autosnippets will expand while typing).')
    elseif auto == false then
      vim.health.warn(
        'LuaSnip `enable_autosnippets` is off. Most latex-tools snippets are autosnippets and will not auto-expand.\n'
          .. 'Call `require("luasnip").config.setup({ enable_autosnippets = true })` in your config.'
      )
    else
      vim.health.warn(
        'Could not read LuaSnip `enable_autosnippets` from session config. If autosnippets never fire, run:\n'
          .. '`require("luasnip").config.setup({ enable_autosnippets = true })`'
      )
    end
  end

  vim.health.start('Treesitter (optional)')
  local parsers = { 'markdown', 'latex' }
  for _, lang in ipairs(parsers) do
    local ok_add, err = pcall(vim.treesitter.language.add, lang)
    if ok_add then
      vim.health.ok(('Parser `%s` is available (better math/context in matching buffers).'):format(lang))
    else
      local tail = type(err) == 'string' and err or tostring(err)
      vim.health.warn(
        ('Parser `%s` is missing or could not load (%s). Markdown math still uses a line-scanner fallback.'):format(
          lang,
          tail
        )
      )
    end
  end

  vim.health.start('latex-tools setup')
  local ok_lt, lt = pcall(require, 'latex-tools')
  if not ok_lt then
    vim.health.error('Could not `require("latex-tools")`. Is the plugin on &runtimepath?')
    return
  end
  local cfg = lt.config
  if type(cfg) ~= 'table' then
    vim.health.warn('`require("latex-tools").setup()` has not been called yet (no merged config). Snippets and keymaps are inactive.')
    vim.health.info('Call `require("latex-tools").setup({ ... })` after LuaSnip is ready.')
    return
  end

  vim.health.ok('`setup()` has been called.')
  local snip = cfg.snippets
  if type(snip) == 'table' then
    if snip.enabled == false then
      vim.health.info('Snippets module is disabled (`snippets.enabled = false`).')
    else
      local fts = snip.filetypes
      if type(fts) == 'table' and #fts > 0 then
        vim.health.info('Snippet filetypes: `' .. table.concat(fts, '`, `') .. '`.')
      end
    end
  end
  if cfg.visual_wrappers and cfg.visual_wrappers.enabled == false then
    vim.health.info('Visual wrappers are disabled (`visual_wrappers.enabled = false`).')
  end
  if cfg.matrix and cfg.matrix.enabled == false then
    vim.health.info('Matrix Enter integration is disabled (`matrix.enabled = false`).')
  end
end

return M
