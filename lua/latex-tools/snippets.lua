-- lua/latex-tools/snippets.lua
-- =============================================================================
-- Purpose: All LaTeX/math autosnippets and regular snippets, extracted from
--          dotfiles nvim/lua/snippets/markdown.lua and
--          nvim/lua/snippets/markdown/math.lua
-- =============================================================================
local M = {}

--- Register all LaTeX math snippets with LuaSnip
--- @param config table Plugin configuration
function M.register(config)
  local ls = require 'luasnip'
  local s = ls.snippet
  local sn = ls.snippet_node
  local t = ls.text_node
  local i = ls.insert_node
  local f = ls.function_node
  local r = ls.restore_node
  local fmt = require('luasnip.extras.fmt').fmt
  local rep = require('luasnip.extras').rep

  local context = require 'latex-tools.context'
  local math_parser = require 'latex-tools.math_parser'

  local in_mathzone = context.is_in_mathzone
  local function in_matrix_env()
    local ok, _ = context.is_in_matrix_env()
    return ok
  end

  local function all(...)
    local conditions = { ... } -- Capture all arguments into a table

    return function(...)
      for _, condition in ipairs(conditions) do
        -- If any condition returns false, stop and return false immediately
        if not condition(...) then
          return false
        end
      end
      -- If we got through the whole list, they all passed
      return true
    end
  end

  -- Check if a trigger is preceded by a backslash or a letter (to avoid double-prefixing)
  local function no_prefix(_, _, captures)
    local c1 = captures[1]
    if not c1 or c1 == '' then
      return true
    end
    return not c1:match '[\\%a]$'
  end

  --------------------------------------------------------------------------------
  -- Smart Snippet Helpers (using math_parser)
  --------------------------------------------------------------------------------

  --- Get cursor position (0-indexed row, col)
  local function get_cursor_0ind()
    local pos = vim.api.nvim_win_get_cursor(0)
    return { pos[1] - 1, pos[2] }
  end

  --- Create a resolveExpandParams function for smart fraction
  --- Uses tokenizer to find the expression before '/' and sets clear_region
  ---@return function resolveExpandParams callback
  local function make_smart_fraction_resolve()
    return function(_snippet, line_to_cursor, matched_trigger, _captures)
      -- Get text before the '/' trigger
      local text_before = line_to_cursor:sub(1, #line_to_cursor - #matched_trigger)
      if text_before == '' then
        return nil -- No expression to capture, don't expand
      end

      local expr, char_start, _char_end = math_parser.get_previous_expression(text_before)
      if expr == '' or char_start == 0 then
        return nil -- No valid expression found
      end

      local pos = get_cursor_0ind()
      -- char_start is 1-indexed position in text_before
      -- We need to clear from that position to cursor
      local clear_start_col = char_start - 1 -- Convert to 0-indexed

      return {
        clear_region = {
          from = { pos[1], clear_start_col },
          to = pos,
        },
        env_override = {
          SMART_FRAC_NUMERATOR = expr,
        },
      }
    end
  end

  --- Create a resolveExpandParams function for smart postfix decorators
  --- Uses tokenizer to find the expression before the decorator keyword
  ---@param _decorator_trigger string the trigger like "hat", "bar", "vec" (unused, for docs)
  ---@return function resolveExpandParams callback
  local function make_smart_postfix_resolve(_decorator_trigger)
    return function(_snippet, line_to_cursor, matched_trigger, _captures)
      local text_before = line_to_cursor:sub(1, #line_to_cursor - #matched_trigger)
      if text_before == '' then
        return nil
      end

      local expr, char_start, _char_end = math_parser.get_previous_expression(text_before)
      if expr == '' or char_start == 0 then
        return nil
      end

      local pos = get_cursor_0ind()
      local clear_start_col = char_start - 1

      return {
        clear_region = {
          from = { pos[1], clear_start_col },
          to = pos,
        },
        env_override = {
          POSTFIX_MATCH = expr,
        },
      }
    end
  end

  -- mk and dm: plain text → math entry (markdown-only, not added to auto_snippets)
  local is_plain_text = context.is_plain_text
  local mk_snippet = s(
    { trig = config.snippets.triggers.inline_math, wordTrig = false,
      snippetType = 'autosnippet', condition = is_plain_text },
    fmt('${}$', { i(1) })
  )
  local dm_snippet = s(
    { trig = config.snippets.triggers.display_math, wordTrig = true,
      snippetType = 'autosnippet', condition = is_plain_text },
    fmt('$$\n{}\n$$', { i(1) })
  )

  -- ==========================================================================
  -- AUTOSNIPPETS (all with condition = in_mathzone or in_matrix_env)
  -- ==========================================================================
  local auto_snippets = {
    -- beg: mA (math, auto, no word boundary)
    s(
      { trig = config.snippets.triggers.begin_env, wordTrig = false, condition = in_mathzone },
      fmt(
        [[\begin{{{}}}
{}
\end{{{}}}]],
        { i(1), i(2), rep(1) }
      )
    ),

    -- ── GREEK LETTERS ( mA, no word boundary ) ──────────────────────────────────
    s({ trig = '@a', wordTrig = false, condition = in_mathzone }, t [[\alpha]]),
    s({ trig = '@b', wordTrig = false, condition = in_mathzone }, t [[\beta]]),
    s({ trig = '@g', wordTrig = false, condition = in_mathzone }, t [[\gamma]]),
    s({ trig = '@G', wordTrig = false, condition = in_mathzone }, t [[\Gamma]]),
    s({ trig = '@d', wordTrig = false, condition = in_mathzone }, t [[\delta]]),
    s({ trig = '@D', wordTrig = false, condition = in_mathzone }, t [[\Delta]]),
    s({ trig = '@e', wordTrig = false, condition = in_mathzone }, t [[\epsilon]]),
    s({ trig = ':e', wordTrig = false, condition = in_mathzone }, t [[\varepsilon]]),
    s({ trig = '@z', wordTrig = false, condition = in_mathzone }, t [[\zeta]]),
    s({ trig = '@h', wordTrig = false, condition = in_mathzone }, t [[\eta]]),
    s({ trig = '@t', wordTrig = false, condition = in_mathzone }, t [[\theta]]),
    s({ trig = '@T', wordTrig = false, condition = in_mathzone }, t [[\Theta]]),
    s({ trig = ':t', wordTrig = false, condition = in_mathzone }, t [[\vartheta]]),
    s({ trig = '@i', wordTrig = false, condition = in_mathzone }, t [[\iota]]),
    s({ trig = '@k', wordTrig = false, condition = in_mathzone }, t [[\kappa]]),
    s({ trig = '@l', wordTrig = false, condition = in_mathzone }, t [[\lambda]]),
    s({ trig = '@L', wordTrig = false, condition = in_mathzone }, t [[\Lambda]]),
    s({ trig = '@m', wordTrig = false, condition = in_mathzone }, t [[\mu]]),
    s({ trig = '@n', wordTrig = false, condition = in_mathzone }, t [[\nu]]),
    s({ trig = '@x', wordTrig = false, condition = in_mathzone }, t [[\xi]]),
    s({ trig = '@X', wordTrig = false, condition = in_mathzone }, t [[\Xi]]),
    s({ trig = '@p', wordTrig = false, condition = in_mathzone }, t [[\pi]]),
    s({ trig = '@r', wordTrig = false, condition = in_mathzone }, t [[\rho]]),
    s({ trig = '@s', wordTrig = false, condition = in_mathzone }, t [[\sigma]]),
    s({ trig = '@S', wordTrig = false, condition = in_mathzone }, t [[\Sigma]]),
    s({ trig = '@u', wordTrig = false, condition = in_mathzone }, t [[\upsilon]]),
    s({ trig = '@U', wordTrig = false, condition = in_mathzone }, t [[\Upsilon]]),
    s({ trig = '@f', wordTrig = false, condition = in_mathzone }, t [[\phi]]),
    s({ trig = ':f', wordTrig = false, condition = in_mathzone }, t [[\varphi]]),
    s({ trig = '@F', wordTrig = false, condition = in_mathzone }, t [[\Phi]]),
    s({ trig = '@y', wordTrig = false, condition = in_mathzone }, t [[\psi]]),
    s({ trig = '@Y', wordTrig = false, condition = in_mathzone }, t [[\Psi]]),
    s({ trig = '@o', wordTrig = false, condition = in_mathzone }, t [[\omega]]),
    s({ trig = '@O', wordTrig = false, condition = in_mathzone }, t [[\Omega]]),
    s({ trig = 'ome', wordTrig = false, condition = in_mathzone }, t [[\omega]]),
    s({ trig = 'Ome', wordTrig = false, condition = in_mathzone }, t [[\Omega]]),

    -- ── TEXT ENVIRONMENT ( mA ) ──────────────────────────────────────────────────
    s({ trig = 'text', wordTrig = false, condition = in_mathzone }, fmt([[\text{<>}<>]], { i(1), i(2) }, { delimiters = '<>' })),
    -- " → \text{} (obsidian shorthand)
    s({ trig = "'", wordTrig = false, condition = in_mathzone }, fmt([[\text{<>}<>]], { i(1), i(2) }, { delimiters = '<>' })),

    -- ── BASIC OPERATIONS ( mA, no word boundary ) ──────────────────────────────
    s({ trig = 'sr', wordTrig = false, condition = in_mathzone }, t '^{2}'),
    s({ trig = 'cb', wordTrig = false, condition = in_mathzone }, t '^{3}'),
    s({ trig = 'rd', wordTrig = false, condition = in_mathzone }, fmt('^{{{}}}{}', { i(1), i(2) })),
    s({ trig = 'us', wordTrig = false, condition = in_mathzone }, fmt('_{{{}}}{}', { i(1), i(2) })),
    s({ trig = 'sts', wordTrig = false, condition = in_mathzone }, fmt([[_\text{{{}}}]], { i(1) })),
    s({ trig = 'sq', wordTrig = false, condition = in_mathzone }, fmt([[\sqrt{{ {} }}{}]], { i(1), i(2) })),
    s({ trig = 'nsq', wordTrig = false, condition = in_mathzone }, fmt([[\sqrt[{}]{{{}}}{}]], { i(1, 'n'), i(2), i(3) })),
    s({ trig = '//', wordTrig = false, condition = in_mathzone }, fmt([[\frac{{{}}}{{{}}}{}]], { i(1), i(2), i(3) })),
    -- [060b] Smart Auto-capture Fraction (mA)
    -- Uses tokenizer to properly handle balanced parens, brackets, and LaTeX commands
    -- Examples: x/ → \frac{x}{}, (a+b)/ → \frac{a+b}{}, \alpha/ → \frac{\alpha}{}
    s(
      {
        trig = '/',
        wordTrig = false,
        condition = in_mathzone,
        resolveExpandParams = make_smart_fraction_resolve(),
      },
      fmt([[\frac{{{}}}{{{}}}]], {
        f(function(_, snip)
          return snip.env.SMART_FRAC_NUMERATOR or ''
        end),
        i(1),
      })
    ),
    s({ trig = 'ee', wordTrig = false, condition = in_mathzone }, fmt([[e^{{ {} }}{}]], { i(1), i(2) })),
    s({ trig = 'invs', wordTrig = false, condition = in_mathzone }, t '^{-1}'),
    s({ trig = 'conj', wordTrig = false, condition = in_mathzone }, t '^{*}'),
    s({ trig = 'Re', wordTrig = false, condition = in_mathzone }, t [[\mathrm{Re}]]),
    s({ trig = 'Im', wordTrig = false, condition = in_mathzone }, t [[\mathrm{Im}]]),
    s({ trig = 'bf', wordTrig = false, condition = in_mathzone }, fmt([[\mathbf{{{}}}]], { i(1) })),
    s({ trig = 'rm', wordTrig = false, condition = in_mathzone }, fmt([[\mathrm{{{}}}{}]], { i(1), i(2) })),
    s({ trig = 'trace', wordTrig = false, condition = in_mathzone }, t [[\mathrm{Tr}]]),

    -- ── SYMBOLS ( mA ) ──────────────────────────────────────────────────────────
    s({ trig = 'ooo', wordTrig = false, condition = in_mathzone }, t [[\infty]]),
    s({ trig = 'sum', wordTrig = false, condition = in_mathzone }, t [[\sum]]),
    s({ trig = 'prod', wordTrig = false, condition = in_mathzone }, t [[\prod]]),
    s({ trig = '+-', wordTrig = false, condition = in_mathzone }, t [[\pm]]),
    s({ trig = '-+', wordTrig = false, condition = in_mathzone }, t [[\mp]]),
    s({ trig = '...', wordTrig = false, condition = in_mathzone }, t [[\dots]]),
    s({ trig = 'nabl', wordTrig = false, condition = in_mathzone }, t [[\nabla]]),
    s({ trig = 'del', wordTrig = false, condition = in_mathzone }, t [[\nabla]]),
    s({ trig = 'xx', wordTrig = false, condition = in_mathzone }, t [[\times]]),
    s({ trig = '**', wordTrig = false, condition = in_mathzone }, fmt([[\cdot {}]], { i(1) })),
    s({ trig = 'para', wordTrig = false, condition = in_mathzone }, t [[\parallel]]),
    s({ trig = '===', wordTrig = false, condition = in_mathzone }, t [[\equiv]]),
    s({ trig = '!=', wordTrig = false, condition = in_mathzone }, t [[\neq]]),
    s({ trig = '>=', wordTrig = false, condition = in_mathzone }, t [[\geq]]),
    s({ trig = '<=', wordTrig = false, condition = in_mathzone }, t [[\leq]]),
    s({ trig = '>>', wordTrig = false, condition = in_mathzone }, t [[\gg]]),
    s({ trig = '<<', wordTrig = false, condition = in_mathzone }, t [[\ll]]),
    s({ trig = 'simm', wordTrig = false, condition = in_mathzone }, t [[\sim]]),
    s({ trig = 'sim=', wordTrig = false, condition = in_mathzone }, t [[\simeq]]),
    s({ trig = 'prop', wordTrig = false, condition = in_mathzone }, t [[\propto]]),
    s({ trig = '~~', wordTrig = false, condition = in_mathzone }, t [[\approx]]),

    -- ── ARROWS ( mA ) ────────────────────────────────────────────────────────────
    s({ trig = '<->', wordTrig = false, condition = in_mathzone }, t [[\leftrightarrow ]]),
    s({ trig = '->', wordTrig = false, condition = in_mathzone }, t [[\to]]),
    s({ trig = '!>', wordTrig = false, condition = in_mathzone }, t [[\mapsto]]),
    s({ trig = '=>', wordTrig = false, condition = in_mathzone }, t [[\implies]]),
    s({ trig = '=<', wordTrig = false, condition = in_mathzone }, t [[\impliedby]]),

    -- ── SETS / LOGIC ( mA ) ──────────────────────────────────────────────────────
    s({ trig = 'and', wordTrig = false, condition = in_mathzone }, t [[\cap]]),
    s({ trig = 'orr', wordTrig = false, condition = in_mathzone }, t [[\cup]]),
    s({ trig = 'inn', wordTrig = false, condition = in_mathzone }, t [[\in]]),
    s({ trig = 'notin', wordTrig = false, condition = in_mathzone }, t [[\not\in]]),
    s({ trig = 'sub=', wordTrig = false, condition = in_mathzone }, t [[\subseteq]]),
    s({ trig = 'sup=', wordTrig = false, condition = in_mathzone }, t [[\supseteq]]),
    s({ trig = 'eset', wordTrig = false, condition = in_mathzone }, t [[\emptyset]]),
    s({ trig = 'set', wordTrig = false, condition = in_mathzone }, fmt([[\{{ {} \}}{}]], { i(1), i(2) })),
    s({ trig = '&&', wordTrig = false, condition = in_mathzone }, t [[\quad \land \quad]]),
    s({ trig = 'LL', wordTrig = false, condition = in_mathzone }, t [[\mathcal{L}]]),
    s({ trig = 'HH', wordTrig = false, condition = in_mathzone }, t [[\mathcal{H}]]),
    s({ trig = 'CC', wordTrig = false, condition = in_mathzone }, t [[\mathbb{C}]]),
    s({ trig = 'RR', wordTrig = false, condition = in_mathzone }, t [[\mathbb{R}]]),
    s({ trig = 'ZZ', wordTrig = false, condition = in_mathzone }, t [[\mathbb{Z}]]),
    s({ trig = 'NN', wordTrig = false, condition = in_mathzone }, t [[\mathbb{N}]]),
    s({ trig = 'QQ', wordTrig = false, condition = in_mathzone }, t [[\mathbb{Q}]]),

    -- ── LOGICAL ARGUMENTS ( mA ) ──────────────────────────────────────────────────
    s({ trig = '?fa', wordTrig = false, condition = in_mathzone }, fmt([[\forall {}]], { i(1) })),
    s({ trig = '?ex', wordTrig = false, condition = in_mathzone }, fmt([[\exists {}]], { i(1) })),
    s({ trig = '?tf', wordTrig = false, condition = in_mathzone }, fmt([[\therefore {}]], { i(1) })),
    s({ trig = '?be', wordTrig = false, condition = in_mathzone }, fmt([[\because {}]], { i(1) })),
    s({ trig = 'neg', wordTrig = false, condition = in_mathzone }, t [[\neg]]),
    s({ trig = '?qed', wordTrig = false, condition = in_mathzone }, t [[\square]]),
    s({ trig = '?st', wordTrig = false, condition = in_mathzone }, t [[\text{ s.t. }]]),
    s({ trig = '?ue', wordTrig = false, condition = in_mathzone }, fmt([[\exists! {}]], { i(1) })),
    s({ trig = 'iff', wordTrig = false, condition = in_mathzone }, t [[\iff]]),

    -- ── DECORATORS ( mA, no word boundary ) ──────────────────────────────────────
    -- NOTE: These plain fmt-based decorators are INTENTIONAL fallbacks.
    -- The smart postfix versions below (priority = 2000) use resolveExpandParams to
    -- capture the preceding expression (e.g. "x_1 hat" → "\hat{x_1}"). When the
    -- cursor has no valid preceding expression, resolveExpandParams returns nil and
    -- LuaSnip falls back to the lower-priority snippet here, allowing the user to
    -- type "hat" with no prior expression and get "\hat{}{}" with a fill-in prompt.
    s({ trig = 'hat', wordTrig = false, condition = in_mathzone }, fmt([[\hat{{{}}}{}]], { i(1), i(2) })),
    s({ trig = 'bar', wordTrig = false, condition = in_mathzone }, fmt([[\bar{{{}}}{}]], { i(1), i(2) })),
    s({ trig = 'dot', wordTrig = false, condition = in_mathzone }, fmt([[\dot{{{}}}{}]], { i(1), i(2) })),
    s({ trig = 'ddot', wordTrig = false, condition = in_mathzone }, fmt([[\ddot{{{}}}{}]], { i(1), i(2) })),
    s({ trig = 'cdot', wordTrig = false, condition = in_mathzone }, t [[\cdot]]),
    s({ trig = 'tilde', wordTrig = false, condition = in_mathzone }, fmt([[\tilde{{{}}}{}]], { i(1), i(2) })),
    s({ trig = 'und', wordTrig = false, condition = in_mathzone }, fmt([[\underline{{{}}}{}]], { i(1), i(2) })),
    s({ trig = 'vec', wordTrig = false, condition = in_mathzone }, fmt([[\vec{{{}}}{}]], { i(1), i(2) })),
    s(
      { trig = 'deco', wordTrig = true, condition = in_mathzone },
      {
        ls.choice_node(1, {
          sn(nil, { t [[\hat{]], r(1, 'deco_expr', i(nil, 'x')), t '}' }),
          sn(nil, { t [[\bar{]], r(1, 'deco_expr'), t '}' }),
          sn(nil, { t [[\dot{]], r(1, 'deco_expr'), t '}' }),
          sn(nil, { t [[\ddot{]], r(1, 'deco_expr'), t '}' }),
          sn(nil, { t [[\tilde{]], r(1, 'deco_expr'), t '}' }),
          sn(nil, { t [[\vec{]], r(1, 'deco_expr'), t '}' }),
          sn(nil, { t [[\underline{]], r(1, 'deco_expr'), t '}' }),
        }, { restore_cursor = true }),
        i(2),
      }
    ),

    -- ── MISC SUBSCRIPT SHORTHANDS ( mA ) ─────────────────────────────────────────
    s({ trig = 'xnn', wordTrig = false, condition = in_mathzone }, t 'x_{n}'),
    s({ trig = 'xjj', wordTrig = false, condition = in_mathzone }, t 'x_{j}'),
    s({ trig = 'xp1', wordTrig = false, condition = in_mathzone }, t 'x_{n+1}'),
    s({ trig = 'ynn', wordTrig = false, condition = in_mathzone }, t 'y_{n}'),
    s({ trig = 'yii', wordTrig = false, condition = in_mathzone }, t 'y_{i}'),
    s({ trig = 'yjj', wordTrig = false, condition = in_mathzone }, t 'y_{j}'),

    -- ── INTEGRALS / DERIVATIVES ( mA ) ───────────────────────────────────────────
    s({ trig = 'ddt', wordTrig = false, condition = in_mathzone }, t [[\frac{d}{dt} ]]),
    s({ trig = 'dint', wordTrig = false, condition = in_mathzone }, fmt([[\int_{{{}}}^{{{}}} {} \, d{} {}]], { i(1, '0'), i(2, '1'), i(3), i(4, 'x'), i(5) })),
    s({ trig = 'iiint', wordTrig = false, condition = in_mathzone }, t [[\iiint]]),
    s({ trig = 'iint', wordTrig = false, condition = in_mathzone }, t [[\iint]]),
    s({ trig = 'oint', wordTrig = false, condition = in_mathzone }, t [[\oint]]),
    s({ trig = 'oinf', wordTrig = false, condition = in_mathzone }, fmt([[\int_{{0}}^{{\infty}} {} \, d{} {}]], { i(1), i(2, 'x'), i(3) })),
    s({ trig = 'infi', wordTrig = false, condition = in_mathzone }, fmt([[\int_{{-\infty}}^{{\infty}} {} \, d{} {}]], { i(1), i(2, 'x'), i(3) })),

    -- ── QUANTUM MECHANICS / PHYSICS ( mA ) ───────────────────────────────────────
    s({ trig = 'dag', wordTrig = false, condition = in_mathzone }, t [[^{\dagger}]]),
    s({ trig = 'o+', wordTrig = false, condition = in_mathzone }, t [[\oplus ]]),
    s({ trig = 'ox', wordTrig = false, condition = in_mathzone }, t [[\otimes ]]),
    s({ trig = 'bra', wordTrig = false, condition = in_mathzone }, fmt([[\bra{{{}}} {}]], { i(1), i(2) })),
    s({ trig = 'ket', wordTrig = false, condition = in_mathzone }, fmt([[\ket{{{}}} {}]], { i(1), i(2) })),
    s({ trig = 'brk', wordTrig = false, condition = in_mathzone }, fmt([[\braket{{ {} | {} }} {}]], { i(1), i(2), i(3) })),
    s({ trig = 'outer', wordTrig = false, condition = in_mathzone }, fmt([[\ket{{{}}} \bra{{{}}} {}]], { i(1, [[\psi]]), rep(1), i(2) })),
    s({ trig = 'kbt', wordTrig = false, condition = in_mathzone }, t 'k_{B}T'),
    s({ trig = 'msun', wordTrig = false, condition = in_mathzone }, t [[M_{\odot}]]),

    -- ── CHEMISTRY ( mA ) ─────────────────────────────────────────────────────────
    s({ trig = 'pu', wordTrig = false, condition = in_mathzone }, fmt([[\pu{{ {} }}]], { i(1) })),
    s({ trig = 'cee', wordTrig = false, condition = in_mathzone }, fmt([[\ce{{ {} }}]], { i(1) })),
    s({ trig = 'he4', wordTrig = false, condition = in_mathzone }, t '{}^{4}_{2}He '),
    s({ trig = 'he3', wordTrig = false, condition = in_mathzone }, t '{}^{3}_{2}He '),
    s({ trig = 'iso', wordTrig = false, condition = in_mathzone }, fmt('{{}}^{{{}}}_{{{}}}{} ', { i(1, '4'), i(2, '2'), i(3, 'He') })),

    -- ── MATRIX SHORTCUTS ( mA ) ──────────────────────────────────────────────────
    -- Matrix column separator: use double-comma to insert ' & '.
    -- Single comma should remain a literal comma; do not autosnippet it.
    s({ trig = config.snippets.triggers.matrix_column, wordTrig = false, snippetType = 'autosnippet', condition = in_matrix_env, priority = 2000 }, t(' & ')),

    -- ── ENVIRONMENTS ( mA ) ──────────────────────────────────────────────────────
    s({ trig = 'pmat', wordTrig = false, condition = in_mathzone }, fmt('\\begin{{pmatrix}}\n{}\n\\end{{pmatrix}}', { i(1) })),
    s({ trig = 'bmat', wordTrig = false, condition = in_mathzone }, fmt('\\begin{{bmatrix}}\n{}\n\\end{{bmatrix}}', { i(1) })),
    s({ trig = 'Bmat', wordTrig = false, condition = in_mathzone }, fmt('\\begin{{Bmatrix}}\n{}\n\\end{{Bmatrix}}', { i(1) })),
    s({ trig = 'vmat', wordTrig = false, condition = in_mathzone }, fmt('\\begin{{vmatrix}}\n{}\n\\end{{vmatrix}}', { i(1) })),
    s({ trig = 'Vmat', wordTrig = false, condition = in_mathzone }, fmt('\\begin{{Vmatrix}}\n{}\n\\end{{Vmatrix}}', { i(1) })),
    s({ trig = 'matrix', wordTrig = false, condition = in_mathzone }, fmt('\\begin{{matrix}}\n{}\n\\end{{matrix}}', { i(1) })),
    s({ trig = 'cases', wordTrig = false, condition = in_mathzone }, fmt('\\begin{{cases}}\n{}\n\\end{{cases}}', { i(1) })),
    s({ trig = 'align', wordTrig = false, condition = in_mathzone }, fmt('\\begin{{align}}\n{}\n\\end{{align}}', { i(1) })),
    s({ trig = 'array', wordTrig = false, condition = in_mathzone }, fmt('\\begin{{array}}\n{}\n\\end{{array}}', { i(1) })),

    -- ── BRACKETS ( mA ) ──────────────────────────────────────────────────────────
    s({ trig = 'avg', wordTrig = false, condition = in_mathzone }, fmt([[\langle {} \rangle {}]], { i(1), i(2) })),
    s({ trig = 'norm', wordTrig = false, condition = in_mathzone }, fmt([[\lvert {} \rvert {}]], { i(1), i(2) })),
    s({ trig = 'Norm', wordTrig = false, condition = in_mathzone }, fmt([[\lVert {} \rVert {}]], { i(1), i(2) })),
    s({ trig = 'ceil', wordTrig = false, condition = in_mathzone }, fmt([[\lceil {} \rceil {}]], { i(1), i(2) })),
    s({ trig = 'floor', wordTrig = false, condition = in_mathzone }, fmt([[\lfloor {} \rfloor {}]], { i(1), i(2) })),
    s({ trig = 'mod', wordTrig = false, condition = in_mathzone }, fmt('|{}|{}', { i(1), i(2) })),
    s(
      { trig = 'brack', wordTrig = true, condition = in_mathzone },
      {
        ls.choice_node(1, {
          sn(nil, { t '\\left( ', r(1, 'brack_expr', i(nil, 'x')), t ' \\right)', i(2) }),
          sn(nil, { t '\\left[ ', r(1, 'brack_expr'), t ' \\right]', i(2) }),
          sn(nil, { t '\\left\\{ ', r(1, 'brack_expr'), t ' \\right\\}', i(2) }),
          sn(nil, { t '\\langle ', r(1, 'brack_expr'), t ' \\rangle ', i(2) }),
          sn(nil, { t '\\left| ', r(1, 'brack_expr'), t ' \\right|', i(2) }),
          sn(nil, { t '\\lVert ', r(1, 'brack_expr'), t ' \\rVert ', i(2) }),
        }, { restore_cursor = true }),
      }
    ),
    s({ trig = 'lr(', wordTrig = false, condition = in_mathzone }, fmt([[\left( {} \right) {}]], { i(1), i(2) })),
    s({ trig = 'lr{', wordTrig = false, condition = in_mathzone }, fmt([[\left\{{ {} \right\}} {}]], { i(1), i(2) })),
    s({ trig = 'lr[', wordTrig = false, condition = in_mathzone }, fmt([[\left[ {} \right] {}]], { i(1), i(2) })),
    s({ trig = 'lr|', wordTrig = false, condition = in_mathzone }, fmt([[\left| {} \right| {}]], { i(1), i(2) })),
    s({ trig = 'lra', wordTrig = false, condition = in_mathzone }, fmt([[\left< {} \right> {}]], { i(1), i(2) })),

    -- ── SEQUENCES & SERIES ( mA ) ────────────────────────────────────────────────
    s({ trig = 'seq', wordTrig = false, condition = in_mathzone }, fmt([[\{{{}_{{{} = {}}}\}}^{{\infty}} {}]], { i(1, 'a_n'), i(2, 'n'), i(3, '1'), i(4) })),
    s({ trig = 'sumn', wordTrig = false, condition = in_mathzone }, fmt([[sum_{{{} = {}}}^{{\infty}} {}]], { i(1, 'n'), i(2, '1'), i(3) })),
    s({ trig = 'sumk', wordTrig = false, condition = in_mathzone }, fmt([[sum_{{{} = {}}}^{{{}}} {}]], { i(1, 'k'), i(2, '1'), i(3, 'n'), i(4) })),
    s({ trig = 'limn', wordTrig = false, condition = in_mathzone }, fmt([[\lim_{{{} \to \infty}} {}]], { i(1, 'n'), i(2) })),
    s({ trig = 'limsup', wordTrig = false, condition = in_mathzone }, fmt([[\limsup_{{{} \to \infty}} {}]], { i(1, 'n'), i(2) })),
    s({ trig = 'liminf', wordTrig = false, condition = in_mathzone }, fmt([[\liminf_{{{} \to \infty}} {}]], { i(1, 'n'), i(2) })),
    s({ trig = 'geom', wordTrig = false, condition = in_mathzone }, fmt([[{} \cdot {}^{{{}-1}} {}]], { i(1, 'a'), i(2, 'r'), i(3, 'n'), i(4) })),
    s({ trig = 'arith', wordTrig = false, condition = in_mathzone }, fmt([[{} + ({} - 1){} {}]], { i(1, 'a'), i(2, 'n'), i(3, 'd'), i(4) })),

    -- ── CUSTOM / MISC ( mA ) ─────────────────────────────────────────────────────
    s(
      { trig = 'tayl', wordTrig = false, condition = in_mathzone },
      fmt(
        [[{}({} + {}) = {}({}) + {}'({}){}  + {}''({}) \frac{{{}^{{2}}}}{{2!}} + \dots{}]],
        { i(1, 'f'), i(2, 'x'), i(3, 'h'), rep(1), rep(2), rep(1), rep(2), rep(3), rep(1), rep(2), rep(3), i(4) }
      )
    ),

    -- ── TRIG FUNCTIONS ( moved to end to prevent shadowing specific snippets like 'dint' ) ──
    s(
      { trig = '(.-)(arcsin)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) },
      f(function(_, snip)
        return snip.captures[1] .. [[\arcsin]]
      end)
    ),
    s(
      { trig = '(.-)(arccos)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) },
      f(function(_, snip)
        return snip.captures[1] .. [[\arccos]]
      end)
    ),
    s(
      { trig = '(.-)(arctan)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) },
      f(function(_, snip)
        return snip.captures[1] .. [[\arctan]]
      end)
    ),
    s(
      { trig = '(.-)(sin)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) },
      f(function(_, snip)
        return snip.captures[1] .. [[\sin]]
      end)
    ),
    s(
      { trig = '(.-)(cos)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) },
      f(function(_, snip)
        return snip.captures[1] .. [[\cos]]
      end)
    ),
    s(
      { trig = '(.-)(tan)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) },
      f(function(_, snip)
        return snip.captures[1] .. [[\tan]]
      end)
    ),
    s(
      { trig = '(.-)(csc)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) },
      f(function(_, snip)
        return snip.captures[1] .. [[\csc]]
      end)
    ),
    s(
      { trig = '(.-)(sec)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) },
      f(function(_, snip)
        return snip.captures[1] .. [[\sec]]
      end)
    ),
    s(
      { trig = '(.-)(cot)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) },
      f(function(_, snip)
        return snip.captures[1] .. [[\cot]]
      end)
    ),
    -- s({ trig = '(.-)(sinh)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) }, f(function(_, snip) return snip.captures[1] .. [[\sinh]] end)),
    -- s({ trig = '(.-)(cosh)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) }, f(function(_, snip) return snip.captures[1] .. [[\cosh]] end)),
    -- s({ trig = '(.-)(tanh)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) }, f(function(_, snip) return snip.captures[1] .. [[\tanh]] end)),
    s(
      { trig = '(.-)(exp)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) },
      f(function(_, snip)
        return snip.captures[1] .. [[\exp]]
      end)
    ),
    s(
      { trig = '(.-)(log)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) },
      f(function(_, snip)
        return snip.captures[1] .. [[\log]]
      end)
    ),
    s(
      { trig = '(.-)(ln)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) },
      f(function(_, snip)
        return snip.captures[1] .. [[\ln]]
      end)
    ),
    s(
      { trig = '(.-)(det)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) },
      f(function(_, snip)
        return snip.captures[1] .. [[\det]]
      end)
    ),
    s(
      { trig = '(.-)(int)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) },
      f(function(_, snip)
        return snip.captures[1] .. [[\int]]
      end)
    ),

    -- ── REGEX AUTOSNIPPETS ( mA, no word boundary ) ───────────────────────────────
    -- Auto letter subscript: x2 → x_{2}
    s(
      {
        trig = '([A-Za-z])(%d)',
        regTrig = true,
        wordTrig = false,
        condition = in_mathzone,
      },
      f(function(_, snip)
        return snip.captures[1] .. '_{' .. snip.captures[2] .. '}'
      end)
    ),

    -- Double-digit subscript: x12 → x_{12}
    s(
      {
        trig = '([A-Za-z])_(%d%d)',
        regTrig = true,
        wordTrig = false,
        condition = in_mathzone,
      },
      f(function(_, snip)
        return snip.captures[1] .. '_{' .. snip.captures[2] .. '}'
      end)
    ),

    -- ── SMART POSTFIX DECORATORS (using tokenizer) ────────────────────────────────
    -- These handle expressions, not just single letters:
    --   xhat → \hat{x}
    --   \alpha hat → \hat{\alpha}
    --   (x+y)hat → \hat{x+y}
    --   x_1 hat → \hat{x_1}

    -- hat decorator
    s(
      {
        trig = 'hat',
        wordTrig = false,
        priority = 2000,
        condition = in_mathzone,
        resolveExpandParams = make_smart_postfix_resolve 'hat',
      },
      f(function(_, snip)
        local expr = snip.env.POSTFIX_MATCH or ''
        return [[\hat{]] .. expr .. '}'
      end)
    ),

    -- bar decorator
    s(
      {
        trig = 'bar',
        wordTrig = false,
        priority = 2000,
        condition = in_mathzone,
        resolveExpandParams = make_smart_postfix_resolve 'bar',
      },
      f(function(_, snip)
        local expr = snip.env.POSTFIX_MATCH or ''
        return [[\bar{]] .. expr .. '}'
      end)
    ),

    -- dot decorator
    s(
      {
        trig = 'dot',
        wordTrig = false,
        priority = 2000,
        condition = in_mathzone,
        resolveExpandParams = make_smart_postfix_resolve 'dot',
      },
      f(function(_, snip)
        local expr = snip.env.POSTFIX_MATCH or ''
        return [[\dot{]] .. expr .. '}'
      end)
    ),

    -- ddot decorator
    s(
      {
        trig = 'ddot',
        wordTrig = false,
        priority = 2000,
        condition = in_mathzone,
        resolveExpandParams = make_smart_postfix_resolve 'ddot',
      },
      f(function(_, snip)
        local expr = snip.env.POSTFIX_MATCH or ''
        return [[\ddot{]] .. expr .. '}'
      end)
    ),

    -- tilde decorator
    s(
      {
        trig = 'tilde',
        wordTrig = false,
        priority = 2000,
        condition = in_mathzone,
        resolveExpandParams = make_smart_postfix_resolve 'tilde',
      },
      f(function(_, snip)
        local expr = snip.env.POSTFIX_MATCH or ''
        return [[\tilde{]] .. expr .. '}'
      end)
    ),

    -- underline decorator
    s(
      {
        trig = 'und',
        wordTrig = false,
        priority = 2000,
        condition = in_mathzone,
        resolveExpandParams = make_smart_postfix_resolve 'und',
      },
      f(function(_, snip)
        local expr = snip.env.POSTFIX_MATCH or ''
        return [[\underline{]] .. expr .. '}'
      end)
    ),

    -- vec decorator
    s(
      {
        trig = 'vec',
        wordTrig = false,
        priority = 2000,
        condition = in_mathzone,
        resolveExpandParams = make_smart_postfix_resolve 'vec',
      },
      f(function(_, snip)
        local expr = snip.env.POSTFIX_MATCH or ''
        return [[\vec{]] .. expr .. '}'
      end)
    ),

    -- Subscripts on decorated letters: \hat{x}2 → \hat{x}_{2}
    s(
      { trig = '\\hat{([A-Za-z])}(%d)', regTrig = true, wordTrig = false, condition = in_mathzone },
      f(function(_, snip)
        return [[\hat{]] .. snip.captures[1] .. '}_{' .. snip.captures[2] .. '}'
      end)
    ),
    s(
      { trig = '\\vec{([A-Za-z])}(%d)', regTrig = true, wordTrig = false, condition = in_mathzone },
      f(function(_, snip)
        return [[\vec{]] .. snip.captures[1] .. '}_{' .. snip.captures[2] .. '}'
      end)
    ),
    s(
      { trig = '\\mathbf{([A-Za-z])}(%d)', regTrig = true, wordTrig = false, condition = in_mathzone },
      f(function(_, snip)
        return [[\mathbf{]] .. snip.captures[1] .. '}_{' .. snip.captures[2] .. '}'
      end)
    ),
  }

  -- Greek letters in text (alpha -> $\alpha$) — programmatically generated
  -- These have condition = is_plain_text in markdown.lua but are math-entry helpers;
  -- they are NOT included here (they depend on is_plain_text / not_in_mathzone).
  -- They stay in markdown.lua.

  -- ==========================================================================
  -- REGULAR SNIPPETS (Tab-triggered) — from markdown/math.lua
  -- ==========================================================================
  local regular_snippets = {
    -- \sum / \prod / \int with limits
    s({ trig = [[\sum]], wordTrig = false, condition = in_mathzone }, fmt([[\sum_{{{} = {}}}^{{{}}} {}]], { i(1, 'i'), i(2, '1'), i(3, 'N'), i(4) })),
    s({ trig = [[\prod]], wordTrig = false, condition = in_mathzone }, fmt([[\prod_{{{} = {}}}^{{{}}} {}]], { i(1, 'i'), i(2, '1'), i(3, 'N'), i(4) })),
    s({ trig = [[\int]], wordTrig = false, condition = in_mathzone }, fmt([[\int {} \, d{} {}]], { i(1), i(2, 'x'), i(3) })),
    s({ trig = 'lim', wordTrig = false, condition = in_mathzone }, fmt([[\lim_{{ {} \to {} }} {}]], { i(1, 'n'), i(2, [[\infty]]), i(3) })),

    -- Partial derivatives
    s({ trig = 'par', wordTrig = false, condition = in_mathzone }, fmt([[\frac{{ \partial {} }}{{ \partial {} }} {}]], { i(1, 'y'), i(2, 'x'), i(3) })),
    s(
      {
        trig = 'pa([A-Za-z])([A-Za-z])',
        regTrig = true,
        wordTrig = false,
        condition = in_mathzone,
      },
      f(function(_, snip)
        return [[\frac{ \partial ]] .. snip.captures[1] .. [[ }{ \partial ]] .. snip.captures[2] .. ' } '
      end)
    ),
  }

  -- ============================================================================
  -- PIPELINE: overrides → disable
  -- ============================================================================
  local function apply_pipeline(snip_list)
    local overrides = config.snippets.overrides or {}
    local disable_set = {}
    for _, trig in ipairs(config.snippets.disable or {}) do
      disable_set[trig] = true
    end

    -- Step 1: apply overrides (mutate trigger fields in-place)
    for _, snip in ipairs(snip_list) do
      local trig = snip.trigger
      if trig and overrides[trig] then
        local ov = overrides[trig]
        if ov.trig     ~= nil then snip.trigger  = ov.trig     end
        if ov.wordTrig ~= nil then snip.wordTrig = ov.wordTrig end
        if ov.regTrig  ~= nil then snip.regTrig  = ov.regTrig  end
      end
    end

    -- Step 2: filter disabled snippets
    local filtered = {}
    for _, snip in ipairs(snip_list) do
      if not disable_set[snip.trigger] then
        table.insert(filtered, snip)
      end
    end

    return filtered
  end

  -- Apply pipeline (overrides → disable) to both tables
  local processed_auto = apply_pipeline(auto_snippets)
  local processed_regular = apply_pipeline(regular_snippets)

  -- mk and dm are markdown-only (plain text condition, not math zone)
  -- They are not in auto_snippets (which goes to tex too) so skip pipeline for them
  ls.add_snippets('markdown', { mk_snippet, dm_snippet }, { key = 'latex-tools-md-entry', type = 'autosnippets' })

  ls.add_snippets('markdown', processed_auto,    { key = 'latex-tools-auto',     type = 'autosnippets' })
  ls.add_snippets('markdown', processed_regular, { key = 'latex-tools-regular' })
  ls.add_snippets('tex',      processed_auto,    { key = 'latex-tools-tex-auto', type = 'autosnippets' })
  ls.add_snippets('tex',      processed_regular, { key = 'latex-tools-tex-regular' })

  -- User-supplied extra snippets (registered after built-ins, once each for both filetypes)
  local extra = config.snippets.extra or {}
  if #extra > 0 then
    ls.add_snippets('markdown', extra, { key = 'latex-tools-extra' })
    ls.add_snippets('tex',      extra, { key = 'latex-tools-tex-extra' })
  end
end

return M
