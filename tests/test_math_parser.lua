-- tests/test_math_parser.lua
local T = MiniTest.new_set()

T['math_parser'] = MiniTest.new_set()

T['math_parser']['tokenize returns exact tokens for simple expression'] = function()
  local mp = require 'latex-tools.math_parser'
  local tokens = mp.tokenize('x^2')
  -- x, ^, 2 → exactly 3 tokens
  MiniTest.expect.equality(#tokens, 3)
  MiniTest.expect.equality(tokens[1].text, 'x')
  MiniTest.expect.equality(tokens[1].start, 1)
  MiniTest.expect.equality(tokens[1].finish, 1)
  MiniTest.expect.equality(tokens[2].text, '^')
  MiniTest.expect.equality(tokens[3].text, '2')
end

T['math_parser']['get_previous_expression extracts simple variable'] = function()
  local mp = require 'latex-tools.math_parser'
  local expr, s, e = mp.get_previous_expression('x')
  MiniTest.expect.equality(expr, 'x')
  MiniTest.expect.equality(s, 1)
  MiniTest.expect.equality(e, 1)
end

T['math_parser']['get_previous_expression extracts last brace group of frac'] = function()
  local mp = require 'latex-tools.math_parser'
  -- get_previous_expression sees only the last balanced group: {b} at positions 9-11
  local expr, s, e = mp.get_previous_expression('\\frac{a}{b}')
  MiniTest.expect.equality(expr, '{b}')
  MiniTest.expect.equality(s, 9)
  MiniTest.expect.equality(e, 11)
end

T['math_parser']['get_previous_expression_with_args extracts full frac command'] = function()
  local mp = require 'latex-tools.math_parser'
  -- get_previous_expression_with_args consumes both brace groups and the command
  local expr, s, e = mp.get_previous_expression_with_args('\\frac{a}{b}')
  MiniTest.expect.equality(expr, '\\frac{a}{b}')
  MiniTest.expect.equality(s, 1)
  MiniTest.expect.equality(e, 11)
end

return T
