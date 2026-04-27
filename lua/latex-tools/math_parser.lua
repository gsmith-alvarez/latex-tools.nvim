-- lua/latex-tools/math_parser.lua
-- =============================================================================
-- Purpose: LaTeX tokenizer and expression grouper for smart snippet expansion.
-- Domain:  Editing / Snippets
--
-- Architecture: Ported from TypeScript reference implementation. Provides:
--               - tokenize(str): Break LaTeX into tokens with positions
--               - get_previous_expression(str): Get logical expression before cursor
--               Uses single-pass scanning with balanced bracket tracking.
--
-- Philosophy:   Regex cannot reliably parse nested structures like LaTeX.
--               By tokenizing first and walking tokens backward, we can
--               properly handle balanced parens, commands, and subscripts
--               for intelligent auto-fractions and postfix decorators.
--
-- Maintenance:
-- 1. Add new token types to readNextToken() for additional LaTeX constructs.
-- 2. Extend CLOSE_TO_OPEN for additional bracket pairs if needed.
-- 3. Test edge cases: nested fracs, commands with multiple args, subscripts.
-- =============================================================================

local M = {}

--------------------------------------------------------------------------------
-- Token type
--------------------------------------------------------------------------------

---@class MathToken
---@field start number 1-indexed start position
---@field finish number 1-indexed end position (inclusive)
---@field text string the token text

--------------------------------------------------------------------------------
-- Tokenizer
--------------------------------------------------------------------------------

--- Check if character is whitespace
---@param char string single character
---@return boolean
local function is_whitespace(char)
  return char:match '%s' ~= nil
end

--- Check if character is alphabetic
---@param char string single character
---@return boolean
local function is_alpha(char)
  return char:match '[A-Za-z]' ~= nil
end

--- Read a comment token starting at position `start`
--- Comments begin with % and extend to end of line (or string)
---@param str string
---@param start number 1-indexed
---@return MathToken token
---@return number next_index
local function read_comment_token(str, start)
  local len = #str
  local current = start + 1

  while current <= len and str:sub(current, current) ~= '\n' do
    current = current + 1
  end

  return {
    start = start,
    finish = current - 1,
    text = str:sub(start, current - 1),
  }, current
end

--- Read an escape/command token starting at position `start`
--- Handles: \command (alphabetic) or \symbol (single non-alpha char)
---@param str string
---@param start number 1-indexed
---@return MathToken token
---@return number next_index
local function read_escape_token(str, start)
  local len = #str
  local current = start + 1

  if current > len then
    -- Lone backslash at end of string
    return {
      start = start,
      finish = start,
      text = '\\',
    }, current
  end

  local next_char = str:sub(current, current)

  if is_alpha(next_char) then
    -- Command token: \sin, \frac, \alpha, etc.
    while current <= len and is_alpha(str:sub(current, current)) do
      current = current + 1
    end
  else
    -- Symbol token: \%, \_, \{, etc.
    current = current + 1
  end

  return {
    start = start,
    finish = current - 1,
    text = str:sub(start, current - 1),
  }, current
end

--- Read a single character token
---@param str string
---@param start number 1-indexed
---@return MathToken token
---@return number next_index
local function read_single_char_token(str, start)
  return {
    start = start,
    finish = start,
    text = str:sub(start, start),
  }, start + 1
end

--- Read the next token from `str` starting at position `start`
---@param str string
---@param start number 1-indexed
---@return MathToken token
---@return number next_index
local function read_next_token(str, start)
  local char = str:sub(start, start)

  if char == '%' then
    return read_comment_token(str, start)
  elseif char == '\\' then
    return read_escape_token(str, start)
  else
    return read_single_char_token(str, start)
  end
end

--- Tokenize a LaTeX string into tokens
--- Whitespace is skipped (not tokenized)
---@param str string LaTeX string to tokenize
---@return MathToken[] tokens
function M.tokenize(str)
  local tokens = {}
  local index = 1
  local len = #str

  while index <= len do
    local char = str:sub(index, index)

    if is_whitespace(char) then
      index = index + 1
    else
      local token, next_index = read_next_token(str, index)
      table.insert(tokens, token)
      index = next_index
    end
  end

  return tokens
end

--------------------------------------------------------------------------------
-- Expression Grouper
--------------------------------------------------------------------------------

--- Bracket/delimiter matching pairs (close -> open)
local CLOSE_TO_OPEN = {
  [')'] = '(',
  [']'] = '[',
  ['}'] = '{',
}

--- Check if a token is a closing bracket
---@param token MathToken
---@return boolean
local function is_close_bracket(token)
  return CLOSE_TO_OPEN[token.text] ~= nil
end

--- Check if a token is a LaTeX command (starts with \)
---@param token MathToken
---@return boolean
local function is_command(token)
  return token.text:sub(1, 1) == '\\'
end

--- Check if a token is a subscript/superscript operator
---@param token MathToken
---@return boolean
local function is_script_operator(token)
  return token.text == '_' or token.text == '^'
end

--- Walk tokens backward from `end_idx` to find the start of a balanced group
--- Returns the index of the opening bracket that matches the closing bracket at end_idx
---@param tokens MathToken[]
---@param end_idx number index of the closing bracket token (1-indexed)
---@return number|nil start_idx index of matching open bracket, or nil if unbalanced
local function find_matching_open(tokens, end_idx)
  local close_token = tokens[end_idx]
  local expected_open = CLOSE_TO_OPEN[close_token.text]
  if not expected_open then
    return nil
  end

  local depth = 1
  local idx = end_idx - 1

  while idx >= 1 and depth > 0 do
    local t = tokens[idx]
    if t.text == close_token.text then
      depth = depth + 1
    elseif t.text == expected_open then
      depth = depth - 1
    end
    idx = idx - 1
  end

  if depth == 0 then
    return idx + 1 -- idx went one past, adjust back
  end

  return nil -- Unbalanced
end

--- Get the "previous expression" from a list of tokens
--- This walks backward from the last token and groups:
--- 1. Balanced bracket groups: (a + b), [i], {n}
--- 2. LaTeX commands with their arguments: \frac{a}{b}, \alpha
--- 3. Variables with subscripts/superscripts: x_1, x^2, x_{ij}
--- 4. Simple single-character variables: x, y, z
---
---@param tokens MathToken[]
---@return number start_idx 1-indexed start of expression in token array
---@return number end_idx 1-indexed end of expression in token array
---@return string expr_text the expression text
local function get_expression_from_tokens(tokens)
  if #tokens == 0 then
    return 0, 0, ''
  end

  local end_idx = #tokens
  local start_idx = end_idx

  local last_token = tokens[end_idx]

  -- Case 1: Closing bracket - find matching open
  if is_close_bracket(last_token) then
    local open_idx = find_matching_open(tokens, end_idx)
    if open_idx then
      start_idx = open_idx
      -- Check if preceded by a command (e.g., \frac{...})
      if open_idx > 1 then
        local prev = tokens[open_idx - 1]
        if is_command(prev) then
          start_idx = open_idx - 1
        end
      end
    end
  -- Case 2: Command - include any following brace groups
  elseif is_command(last_token) then
    -- Command by itself (no args captured yet)
    start_idx = end_idx
  -- Case 3: Single character - check for preceding subscript/superscript chain
  else
    -- Walk backward through subscript/superscript chains: x_1, x_{ab}, x^2_3
    local idx = end_idx

    while idx >= 1 do
      local t = tokens[idx]

      -- If this is a closing brace, find its opening
      if is_close_bracket(t) then
        local open_idx = find_matching_open(tokens, idx)
        if open_idx then
          idx = open_idx
        else
          break
        end
      end

      -- Check if preceded by script operator
      if idx > 1 then
        local prev = tokens[idx - 1]
        if is_script_operator(prev) then
          -- Move past the operator
          idx = idx - 2
          -- Continue to look for more scripts or the base
        else
          break
        end
      else
        break
      end
    end

    -- Now idx points at the base variable/command
    if idx >= 1 then
      start_idx = idx
    end
  end

  -- Build the expression text from start_idx to end_idx
  local parts = {}
  for i = start_idx, end_idx do
    table.insert(parts, tokens[i].text)
  end

  return start_idx, end_idx, table.concat(parts)
end

--- Get the previous logical expression from a LaTeX string
--- This is the main entry point for snippet expansion
---
--- Examples:
---   "x + y"     -> "y"       (single variable)
---   "x_1"       -> "x_1"     (variable with subscript)
---   "(a + b)"   -> "(a + b)" (balanced parens)
---   "\\alpha"   -> "\\alpha" (command)
---   "\\frac{a}{b}" -> "\\frac{a}{b}" (command with args)
---
---@param str string LaTeX string (text before cursor)
---@return string expression the previous expression
---@return number char_start 1-indexed character position where expression starts
---@return number char_end 1-indexed character position where expression ends
function M.get_previous_expression(str)
  local tokens = M.tokenize(str)

  if #tokens == 0 then
    return '', 0, 0
  end

  local start_idx, end_idx, expr_text = get_expression_from_tokens(tokens)

  if start_idx == 0 then
    return '', 0, 0
  end

  local char_start = tokens[start_idx].start
  local char_end = tokens[end_idx].finish

  return expr_text, char_start, char_end
end

--- Get the previous expression, consuming multiple brace groups after a command
--- This handles commands like \frac{a}{b} or \sqrt[n]{x}
---
--- @param str string LaTeX string (text before cursor)
--- @param max_brace_groups number maximum number of brace groups to consume (default 2)
--- @return string expression
--- @return number char_start
--- @return number char_end
function M.get_previous_expression_with_args(str, max_brace_groups)
  max_brace_groups = max_brace_groups or 2

  local tokens = M.tokenize(str)

  if #tokens == 0 then
    return '', 0, 0
  end

  local end_idx = #tokens
  local start_idx = end_idx
  local brace_groups_consumed = 0

  -- Walk backward, consuming brace groups
  local idx = end_idx

  while idx >= 1 and brace_groups_consumed < max_brace_groups do
    local t = tokens[idx]

    if is_close_bracket(t) and t.text == '}' then
      local open_idx = find_matching_open(tokens, idx)
      if open_idx then
        start_idx = open_idx
        idx = open_idx - 1
        brace_groups_consumed = brace_groups_consumed + 1
      else
        break
      end
    elseif is_command(t) then
      start_idx = idx
      break
    else
      -- Not a brace group or command, stop
      break
    end
  end

  -- After consuming brace groups, check if preceded by a command
  if idx >= 1 and is_command(tokens[idx]) then
    start_idx = idx
  end

  -- Build expression
  local parts = {}
  for i = start_idx, end_idx do
    table.insert(parts, tokens[i].text)
  end

  local char_start = tokens[start_idx].start
  local char_end = tokens[end_idx].finish

  return table.concat(parts), char_start, char_end
end

return M
