-- Minimal vendored subset of mini.test for this plugin's unit tests.
-- Provides: MiniTest.new_set(), MiniTest.expect.equality(), MiniTest.run_file().
-- This is intentionally tiny and only supports what this repo's tests use.

local MiniTest = {}

MiniTest._config = {
  execute = {
    reporter = function(msg) io.stdout:write(msg .. '\n') end,
  },
}

function MiniTest.setup(cfg)
  if type(cfg) ~= 'table' then return end
  MiniTest._config = vim.tbl_deep_extend('force', MiniTest._config, cfg)
end

MiniTest.expect = {}

function MiniTest.expect.equality(a, b)
  if a ~= b then
    error(('MiniTest.expect.equality failed:\n  got: %s\n  exp: %s'):format(vim.inspect(a), vim.inspect(b)))
  end
end

function MiniTest.new_set()
  return {}
end

MiniTest.gen_reporter = {}

function MiniTest.gen_reporter.stdout(_opts)
  return function(msg)
    io.stdout:write(msg .. '\n')
  end
end

local function is_callable(x)
  return type(x) == 'function'
end

local function run_set(prefix, set)
  for k, v in pairs(set) do
    local name = prefix ~= '' and (prefix .. ' :: ' .. k) or k
    if is_callable(v) then
      local ok, err = pcall(v)
      if ok then
        MiniTest._config.execute.reporter('ok  - ' .. name)
      else
        MiniTest._config.execute.reporter('not ok - ' .. name)
        error(err)
      end
    elseif type(v) == 'table' then
      run_set(name, v)
    end
  end
end

function MiniTest.run_file(path)
  local chunk, load_err = loadfile(path)
  if not chunk then error(load_err) end
  local set = chunk()
  if type(set) ~= 'table' then error('MiniTest.run_file expected file to return a table') end
  run_set('', set)
end

_G.MiniTest = MiniTest
return MiniTest

