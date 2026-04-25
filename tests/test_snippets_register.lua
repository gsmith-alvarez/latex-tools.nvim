local T = MiniTest.new_set()
T['snippets.register'] = MiniTest.new_set()

local function make_luasnip_stub()
  local stub = {
    _added = {},
  }

  local function mk_snip(spec)
    return { trigger = spec.trig, spec = spec }
  end

  stub.snippet = function(spec, _nodes, _opts) return mk_snip(spec) end
  stub.snippet_node = function(_, _) return {} end
  stub.text_node = function(_) return {} end
  stub.insert_node = function(_, _) return {} end
  stub.choice_node = function(_, _) return {} end
  stub.dynamic_node = function(_, _) return {} end
  stub.function_node = function(_, _) return {} end
  stub.restore_node = function(_, _) return {} end

  stub.add_snippets = function(ft, snippets, opts)
    stub._added[ft] = stub._added[ft] or {}
    table.insert(stub._added[ft], { snippets = snippets, opts = opts })
  end

  return stub
end

local function install_stubs()
  package.loaded['luasnip'] = make_luasnip_stub()
  package.loaded['luasnip.extras.fmt'] = { fmt = function(_, _) return {} end }
  package.loaded['luasnip.extras'] = { rep = function(_) return {} end }
  package.loaded['luasnip.util.events'] = { enter = 'enter' }
end

local function base_config()
  return {
    snippets = {
      enabled = true,
      filetypes = { 'markdown' },
      triggers = { inline_math = 'mk', display_math = 'dm', begin_env = 'beg', matrix_column = ',,' },
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
      overrides = {},
      disable = {},
      extra = {},
    },
    visual_wrappers = { enabled = false },
    matrix = { enabled = false },
    context = { use_treesitter = false },
  }
end

local function flatten_triggers(added)
  local out = {}
  for _, batch in ipairs(added or {}) do
    for _, snip in ipairs(batch.snippets or {}) do
      if type(snip) == 'table' and type(snip.trigger) == 'string' then
        out[snip.trigger] = true
      end
    end
  end
  return out
end

T['snippets.register']['respects snippets.filetypes (markdown only)'] = function()
  install_stubs()
  local cfg = base_config()

  require('latex-tools.snippets').register(cfg)

  local ls = require('luasnip')
  MiniTest.expect.equality(ls._added.tex == nil, true)
  MiniTest.expect.equality(ls._added.markdown ~= nil, true)
end

T['snippets.register']['categories can disable a representative snippet'] = function()
  install_stubs()
  local cfg = base_config()
  cfg.snippets.categories.greek_letters = false

  require('latex-tools.snippets').register(cfg)

  local ls = require('luasnip')
  local triggers = flatten_triggers(ls._added.markdown)
  MiniTest.expect.equality(triggers['@a'] == true, false)
end

T['snippets.register']['disable still removes a snippet even if category enabled'] = function()
  install_stubs()
  local cfg = base_config()
  cfg.snippets.disable = { '@a' }

  require('latex-tools.snippets').register(cfg)

  local ls = require('luasnip')
  local triggers = flatten_triggers(ls._added.markdown)
  MiniTest.expect.equality(triggers['@a'] == true, false)
end

T['snippets.register']['plain // fraction snippet is removed'] = function()
  install_stubs()
  local cfg = base_config()

  require('latex-tools.snippets').register(cfg)

  local ls = require('luasnip')
  local triggers = flatten_triggers(ls._added.markdown)
  MiniTest.expect.equality(triggers['//'] == true, false)
end

local DYN_MAT = '(%d+)%*(%d+)([bBpvV])mat'

T['snippets.register']['dynamic matrix regTrig is present by default'] = function()
  install_stubs()
  local cfg = base_config()

  require('latex-tools.snippets').register(cfg)

  local ls = require('luasnip')
  local triggers = flatten_triggers(ls._added.markdown)
  MiniTest.expect.equality(triggers[DYN_MAT] == true, true)
end

T['snippets.register']['disabling matrices category removes dynamic matrix trigger'] = function()
  install_stubs()
  local cfg = base_config()
  cfg.snippets.categories.matrices = false

  require('latex-tools.snippets').register(cfg)

  local ls = require('luasnip')
  local triggers = flatten_triggers(ls._added.markdown)
  MiniTest.expect.equality(triggers[DYN_MAT] == true, false)
end

T['snippets.register']['disable removes dynamic matrix by regTrig key'] = function()
  install_stubs()
  local cfg = base_config()
  cfg.snippets.disable = { DYN_MAT }

  require('latex-tools.snippets').register(cfg)

  local ls = require('luasnip')
  local triggers = flatten_triggers(ls._added.markdown)
  MiniTest.expect.equality(triggers[DYN_MAT] == true, false)
end

return T

