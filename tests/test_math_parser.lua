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

T['math_parser']['tokenize groups contiguous alnum as one token'] = function()
  local mp = require 'latex-tools.math_parser'
  local tokens = mp.tokenize('hello')
  MiniTest.expect.equality(#tokens, 1)
  MiniTest.expect.equality(tokens[1].text, 'hello')
end

T['math_parser']['get_fraction_numerator captures decimals and words'] = function()
  local mp = require 'latex-tools.math_parser'

  local expr, s, e = mp.get_fraction_numerator('17.3')
  MiniTest.expect.equality(expr, '17.3')
  MiniTest.expect.equality(s, 1)
  MiniTest.expect.equality(e, 4)

  expr, s, e = mp.get_fraction_numerator('prefix 17.3')
  MiniTest.expect.equality(expr, '17.3')
  MiniTest.expect.equality(s, 8)
  MiniTest.expect.equality(e, 11)

  expr, s, e = mp.get_fraction_numerator('Mu_Z')
  MiniTest.expect.equality(expr, 'Mu_Z')
end

T['math_parser']['get_fraction_numerator strips leading math delimiters at line start'] = function()
  local mp = require 'latex-tools.math_parser'

  local expr, s, e = mp.get_fraction_numerator('$17.3')
  MiniTest.expect.equality(expr, '17.3')
  MiniTest.expect.equality(s, 2)
  MiniTest.expect.equality(e, 5)

  expr, s, e = mp.get_fraction_numerator('$$x')
  MiniTest.expect.equality(expr, 'x')
  MiniTest.expect.equality(s, 3)
  MiniTest.expect.equality(e, 3)
end

T['math_parser']['get_fraction_numerator captures inside brace groups only'] = function()
  local mp = require 'latex-tools.math_parser'

  local expr, s, e = mp.get_fraction_numerator('x^{1')
  MiniTest.expect.equality(expr, '1')
  MiniTest.expect.equality(s, 4)
  MiniTest.expect.equality(e, 4)

  expr, s, e = mp.get_fraction_numerator('x^{10')
  MiniTest.expect.equality(expr, '10')
  MiniTest.expect.equality(s, 4)
  MiniTest.expect.equality(e, 5)
end

T['math_parser']['get_fraction_numerator captures denominator prefix in nested frac'] = function()
  local mp = require 'latex-tools.math_parser'

  local expr, s, e = mp.get_fraction_numerator('\\frac{a}{b')
  MiniTest.expect.equality(expr, 'b')
  MiniTest.expect.equality(s, 10)
  MiniTest.expect.equality(e, 10)
end

T['math_parser']['get_fraction_numerator rejects unbalanced brace capture'] = function()
  local mp = require 'latex-tools.math_parser'

  local expr, s, e = mp.get_fraction_numerator('x^{')
  MiniTest.expect.equality(expr, '')
  MiniTest.expect.equality(s, 0)
  MiniTest.expect.equality(e, 0)
end

T['math_parser']['get_fraction_numerator keeps decimal literals intact'] = function()
  local mp = require 'latex-tools.math_parser'

  local expr, s, e = mp.get_fraction_numerator('17.3')
  MiniTest.expect.equality(expr, '17.3')
  MiniTest.expect.equality(s, 1)
  MiniTest.expect.equality(e, 4)
end

T['math_parser']['get_previous_expression extracts contiguous word'] = function()
  local mp = require 'latex-tools.math_parser'

  local expr, s, e = mp.get_previous_expression('velocity')
  MiniTest.expect.equality(expr, 'velocity')
  MiniTest.expect.equality(s, 1)
  MiniTest.expect.equality(e, 8)
end

T['math_parser']['line_before_trigger strips trigger only when present'] = function()
  local mp = require 'latex-tools.math_parser'
  MiniTest.expect.equality(mp.line_before_trigger('hello/', '/'), 'hello')
  MiniTest.expect.equality(mp.line_before_trigger('hello', '/'), 'hello')
end

T['math_parser']['clear_region_for_expr clears from char_start through cursor'] = function()
  local mp = require 'latex-tools.math_parser'
  local region = mp.clear_region_for_expr({ 0, 6 }, 1)
  MiniTest.expect.equality(region.from[1], 0)
  MiniTest.expect.equality(region.from[2], 0)
  MiniTest.expect.equality(region.to[1], 0)
  MiniTest.expect.equality(region.to[2], 6)
end

T['math_parser']['clear_region_for_expr uses char_start not expr length'] = function()
  local mp = require 'latex-tools.math_parser'
  local region = mp.clear_region_for_expr({ 0, 5 }, 1)
  MiniTest.expect.equality(region.from[2], 0)
  MiniTest.expect.equality(region.to[2], 5)
end

T['math_parser']['get_fraction_numerator preserves spaces inside text command'] = function()
  local mp = require 'latex-tools.math_parser'
  local input = [[\text{Moles of solute}]]

  local expr, s, e = mp.get_fraction_numerator(input)
  MiniTest.expect.equality(expr, input)
  MiniTest.expect.equality(s, 1)
  MiniTest.expect.equality(e, #input)

  local region = mp.clear_region_for_expr({ 0, #input }, s)
  MiniTest.expect.equality(region.from[2], 0)
end

T['math_parser']['get_previous_expression extracts word with subscript suffix'] = function()
  local mp = require 'latex-tools.math_parser'

  local expr, s, e = mp.get_previous_expression('Mu_Z')
  MiniTest.expect.equality(expr, 'Mu_Z')
  MiniTest.expect.equality(s, 1)
  MiniTest.expect.equality(e, 4)
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
