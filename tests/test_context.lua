-- tests/test_context.lua
local T = MiniTest.new_set()
T['context'] = MiniTest.new_set()

T['context']['is_in_mathzone returns false in plain markdown text'] = function()
  local ctx = require 'latex-tools.context'
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].filetype = 'markdown'
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'Hello world' })
  vim.api.nvim_win_set_cursor(0, { 1, 5 })
  MiniTest.expect.equality(ctx.is_in_mathzone(), false)
  vim.api.nvim_buf_delete(buf, { force = true })
end

T['context']['is_in_mathzone returns true inside inline math'] = function()
  local ctx = require 'latex-tools.context'
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].filetype = 'markdown'
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'Text $x + y$ more' })
  vim.api.nvim_win_set_cursor(0, { 1, 8 })
  MiniTest.expect.equality(ctx.is_in_mathzone(), true)
  vim.api.nvim_buf_delete(buf, { force = true })
end

T['context']['is_in_mathzone returns true for tex filetype'] = function()
  local ctx = require 'latex-tools.context'
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].filetype = 'tex'
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'plain text here' })
  vim.api.nvim_win_set_cursor(0, { 1, 5 })
  MiniTest.expect.equality(ctx.is_in_mathzone(), true)
  vim.api.nvim_buf_delete(buf, { force = true })
end

T['context']['is_in_mathzone returns false for unknown filetype'] = function()
  local ctx = require 'latex-tools.context'
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].filetype = 'python'
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'x = 1' })
  vim.api.nvim_win_set_cursor(0, { 1, 3 })
  MiniTest.expect.equality(ctx.is_in_mathzone(), false)
  vim.api.nvim_buf_delete(buf, { force = true })
end

T['context']['is_in_matrix_env returns false outside matrix'] = function()
  local ctx = require 'latex-tools.context'
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].filetype = 'tex'
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'just text' })
  vim.api.nvim_win_set_cursor(0, { 1, 3 })
  local in_mat, env = ctx.is_in_matrix_env()
  MiniTest.expect.equality(in_mat, false)
  MiniTest.expect.equality(env, nil)
  vim.api.nvim_buf_delete(buf, { force = true })
end

T['context']['is_in_matrix_env returns true inside pmatrix'] = function()
  local ctx = require 'latex-tools.context'
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].filetype = 'tex'
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    '\\begin{pmatrix}',
    'a & b \\\\',
    'c & d',
  })
  vim.api.nvim_win_set_cursor(0, { 2, 4 })
  local in_mat, env = ctx.is_in_matrix_env()
  MiniTest.expect.equality(in_mat, true)
  MiniTest.expect.equality(env, 'pmatrix')
  vim.api.nvim_buf_delete(buf, { force = true })
end

T['context']['is_in_matrix_env returns false after end environment'] = function()
  local ctx = require 'latex-tools.context'
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].filetype = 'tex'
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    '\\begin{pmatrix}',
    'a & b',
    '\\end{pmatrix}',
    'text after',
  })
  vim.api.nvim_win_set_cursor(0, { 4, 2 })
  local in_mat, _ = ctx.is_in_matrix_env()
  MiniTest.expect.equality(in_mat, false)
  vim.api.nvim_buf_delete(buf, { force = true })
end

T['context']['is_in_mathzone returns true inside display math'] = function()
  local ctx = require 'latex-tools.context'
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].filetype = 'markdown'
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    '$$',
    'x + y = z',
    '$$',
  })
  vim.api.nvim_win_set_cursor(0, { 2, 4 })  -- inside display math
  MiniTest.expect.equality(ctx.is_in_mathzone(), true)
  vim.api.nvim_buf_delete(buf, { force = true })
end

T['context']['is_in_mathzone ignores escaped dollar signs'] = function()
  local ctx = require 'latex-tools.context'
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].filetype = 'markdown'
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'Cost: \\$50 and \\$100' })
  vim.api.nvim_win_set_cursor(0, { 1, 12 })  -- between the two \$
  MiniTest.expect.equality(ctx.is_in_mathzone(), false)
  vim.api.nvim_buf_delete(buf, { force = true })
end

T['context']['is_in_matrix_env true in markdown display math matrix'] = function()
  local ctx = require 'latex-tools.context'
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].filetype = 'markdown'
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    '$$',
    '\\begin{pmatrix}',
    'a & b',
    '\\end{pmatrix}',
    '$$',
  })
  vim.api.nvim_win_set_cursor(0, { 3, 2 })  -- inside pmatrix inside $$
  local in_mat, env = ctx.is_in_matrix_env()
  MiniTest.expect.equality(in_mat, true)
  MiniTest.expect.equality(env, 'pmatrix')
  vim.api.nvim_buf_delete(buf, { force = true })
end

T['context']['is_in_code_block returns false outside code block'] = function()
  local ctx = require 'latex-tools.context'
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].filetype = 'markdown'
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'Hello world' })
  vim.api.nvim_win_set_cursor(0, { 1, 5 })
  MiniTest.expect.equality(ctx.is_in_code_block(), false)
  vim.api.nvim_buf_delete(buf, { force = true })
end

T['context']['is_in_code_block returns true inside fenced code block'] = function()
  local ctx = require 'latex-tools.context'
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].filetype = 'markdown'
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { '```lua', 'x = 1', '```' })
  vim.api.nvim_win_set_cursor(0, { 2, 3 })
  MiniTest.expect.equality(ctx.is_in_code_block(), true)
  vim.api.nvim_buf_delete(buf, { force = true })
end

T['context']['is_plain_text returns true in plain markdown text'] = function()
  local ctx = require 'latex-tools.context'
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].filetype = 'markdown'
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'Hello world' })
  vim.api.nvim_win_set_cursor(0, { 1, 5 })
  MiniTest.expect.equality(ctx.is_plain_text(), true)
  vim.api.nvim_buf_delete(buf, { force = true })
end

T['context']['is_plain_text returns false inside math zone'] = function()
  local ctx = require 'latex-tools.context'
  local buf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].filetype = 'markdown'
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'Text $x + y$ more' })
  vim.api.nvim_win_set_cursor(0, { 1, 8 })
  MiniTest.expect.equality(ctx.is_plain_text(), false)
  vim.api.nvim_buf_delete(buf, { force = true })
end

return T
