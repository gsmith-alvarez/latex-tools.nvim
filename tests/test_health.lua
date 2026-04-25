-- tests/test_health.lua — smoke coverage for :checkhealth latex-tools
local T = MiniTest.new_set()
T['health'] = MiniTest.new_set()

T['health']['check does not throw in minimal test environment'] = function()
  package.loaded['latex-tools.health'] = nil
  local mod = require('latex-tools.health')
  local ok, err = pcall(mod.check)
  MiniTest.expect.equality(ok, true, err)
end

T['health']['check runs with stubbed luasnip and latex-tools'] = function()
  local saved = {
    luasnip = package.loaded['luasnip'],
    ['luasnip.session'] = package.loaded['luasnip.session'],
    ['latex-tools'] = package.loaded['latex-tools'],
    ['latex-tools.health'] = package.loaded['latex-tools.health'],
  }

  package.loaded['luasnip'] = {}
  package.loaded['luasnip.session'] = { config = { enable_autosnippets = true } }
  package.loaded['latex-tools'] = {
    config = {
      snippets = { enabled = true, filetypes = { 'markdown', 'tex' } },
      visual_wrappers = { enabled = true },
      matrix = { enabled = true },
    },
  }
  package.loaded['latex-tools.health'] = nil

  local lang = vim.treesitter.language
  local add_orig = lang.add
  lang.add = function()
    return true
  end

  local h_orig = {}
  for _, name in ipairs({ 'start', 'ok', 'warn', 'error', 'info' }) do
    h_orig[name] = vim.health[name]
    vim.health[name] = function() end
  end

  local ok, err = pcall(function()
    require('latex-tools.health').check()
  end)

  for _, name in ipairs({ 'start', 'ok', 'warn', 'error', 'info' }) do
    vim.health[name] = h_orig[name]
  end
  lang.add = add_orig

  for k, v in pairs(saved) do
    package.loaded[k] = v
  end
  package.loaded['latex-tools.health'] = nil

  MiniTest.expect.equality(ok, true, err)
end

return T
