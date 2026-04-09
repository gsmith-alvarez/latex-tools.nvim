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

  -- ============================================================================
  -- PRE-CONSTRUCTION TRIGGER OVERRIDES
  -- Build lookup tables so snippet construction uses the user-configured trigger.
  -- This must happen before any s() calls, because LuaSnip bakes the trigger
  -- into the trig_matcher closure at construction time.
  -- ============================================================================
  local trig_overrides = {}
  for orig, ov in pairs(config.snippets.overrides or {}) do
    if ov.trig ~= nil then
      trig_overrides[orig] = ov.trig
    end
  end

  -- Wrapper around s() that applies trigger overrides at construction time.
  -- Usage: same as s(), but if config.snippets.overrides has an entry for this
  -- snippet's trigger, the override is applied before LuaSnip compiles it.
  local function sa(spec, ...)
    if trig_overrides[spec.trig] then
      spec = vim.tbl_extend('force', spec, { trig = trig_overrides[spec.trig] })
    end
    return s(spec, ...)
  end

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
    sa(
      { trig = config.snippets.triggers.begin_env, wordTrig = false, condition = in_mathzone },
      fmt(
        [[\begin{{{}}}
{}
\end{{{}}}]],
        { i(1), i(2), rep(1) }
      )
    ),

    -- ── GREEK LETTERS ( mA, no word boundary ) ──────────────────────────────────
    sa({ trig = '@a', wordTrig = false, condition = in_mathzone }, t [[\alpha]]),
    sa({ trig = '@b', wordTrig = false, condition = in_mathzone }, t [[\beta]]),
    sa({ trig = '@g', wordTrig = false, condition = in_mathzone }, t [[\gamma]]),
    sa({ trig = '@G', wordTrig = false, condition = in_mathzone }, t [[\Gamma]]),
    sa({ trig = '@d', wordTrig = false, condition = in_mathzone }, t [[\delta]]),
    sa({ trig = '@D', wordTrig = false, condition = in_mathzone }, t [[\Delta]]),
    sa({ trig = '@e', wordTrig = false, condition = in_mathzone }, t [[\epsilon]]),
    sa({ trig = ':e', wordTrig = false, condition = in_mathzone }, t [[\varepsilon]]),
    sa({ trig = '@z', wordTrig = false, condition = in_mathzone }, t [[\zeta]]),
    sa({ trig = '@h', wordTrig = false, condition = in_mathzone }, t [[\eta]]),
    sa({ trig = '@t', wordTrig = false, condition = in_mathzone }, t [[\theta]]),
    sa({ trig = '@T', wordTrig = false, condition = in_mathzone }, t [[\Theta]]),
    sa({ trig = ':t', wordTrig = false, condition = in_mathzone }, t [[\vartheta]]),
    sa({ trig = '@i', wordTrig = false, condition = in_mathzone }, t [[\iota]]),
    sa({ trig = '@k', wordTrig = false, condition = in_mathzone }, t [[\kappa]]),
    sa({ trig = '@l', wordTrig = false, condition = in_mathzone }, t [[\lambda]]),
    sa({ trig = '@L', wordTrig = false, condition = in_mathzone }, t [[\Lambda]]),
    sa({ trig = '@m', wordTrig = false, condition = in_mathzone }, t [[\mu]]),
    sa({ trig = '@n', wordTrig = false, condition = in_mathzone }, t [[\nu]]),
    sa({ trig = '@x', wordTrig = false, condition = in_mathzone }, t [[\xi]]),
    sa({ trig = '@X', wordTrig = false, condition = in_mathzone }, t [[\Xi]]),
    sa({ trig = '@p', wordTrig = false, condition = in_mathzone }, t [[\pi]]),
    sa({ trig = '@r', wordTrig = false, condition = in_mathzone }, t [[\rho]]),
    sa({ trig = '@s', wordTrig = false, condition = in_mathzone }, t [[\sigma]]),
    sa({ trig = '@S', wordTrig = false, condition = in_mathzone }, t [[\Sigma]]),
    sa({ trig = '@u', wordTrig = false, condition = in_mathzone }, t [[\upsilon]]),
    sa({ trig = '@U', wordTrig = false, condition = in_mathzone }, t [[\Upsilon]]),
    sa({ trig = '@f', wordTrig = false, condition = in_mathzone }, t [[\phi]]),
    sa({ trig = ':f', wordTrig = false, condition = in_mathzone }, t [[\varphi]]),
    sa({ trig = '@F', wordTrig = false, condition = in_mathzone }, t [[\Phi]]),
    sa({ trig = '@y', wordTrig = false, condition = in_mathzone }, t [[\psi]]),
    sa({ trig = '@Y', wordTrig = false, condition = in_mathzone }, t [[\Psi]]),
    sa({ trig = '@o', wordTrig = false, condition = in_mathzone }, t [[\omega]]),
    sa({ trig = '@O', wordTrig = false, condition = in_mathzone }, t [[\Omega]]),
    sa({ trig = 'ome', wordTrig = false, condition = in_mathzone }, t [[\omega]]),
    sa({ trig = 'Ome', wordTrig = false, condition = in_mathzone }, t [[\Omega]]),

    -- ── TEXT ENVIRONMENT ( mA ) ──────────────────────────────────────────────────
    sa({ trig = 'text', wordTrig = false, condition = in_mathzone }, fmt([[\text{<>}<>]], { i(1), i(2) }, { delimiters = '<>' })),
    -- " → \text{} (obsidian shorthand)
    sa({ trig = "'", wordTrig = false, condition = in_mathzone }, fmt([[\text{<>}<>]], { i(1), i(2) }, { delimiters = '<>' })),

    -- ── BASIC OPERATIONS ( mA, no word boundary ) ──────────────────────────────
    sa({ trig = 'sr', wordTrig = false, condition = in_mathzone }, t '^{2}'),
    sa({ trig = 'cb', wordTrig = false, condition = in_mathzone }, t '^{3}'),
    sa({ trig = 'rd', wordTrig = false, condition = in_mathzone }, fmt('^{{{}}}{}', { i(1), i(2) })),
    sa({ trig = 'us', wordTrig = false, condition = in_mathzone }, fmt('_{{{}}}{}', { i(1), i(2) })),
    sa({ trig = 'sts', wordTrig = false, condition = in_mathzone }, fmt([[_\text{{{}}}]], { i(1) })),
    sa({ trig = 'sq', wordTrig = false, condition = in_mathzone }, fmt([[\sqrt{{ {} }}{}]], { i(1), i(2) })),
    sa({ trig = 'nsq', wordTrig = false, condition = in_mathzone }, fmt([[\sqrt[{}]{{{}}}{}]], { i(1, 'n'), i(2), i(3) })),
    sa({ trig = '//', wordTrig = false, condition = in_mathzone }, fmt([[\frac{{{}}}{{{}}}{}]], { i(1), i(2), i(3) })),
    -- [060b] Smart Auto-capture Fraction (mA)
    -- Uses tokenizer to properly handle balanced parens, brackets, and LaTeX commands
    -- Examples: x/ → \frac{x}{}, (a+b)/ → \frac{a+b}{}, \alpha/ → \frac{\alpha}{}
    sa(
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
    sa({ trig = 'ee', wordTrig = false, condition = in_mathzone }, fmt([[e^{{ {} }}{}]], { i(1), i(2) })),
    sa({ trig = 'invs', wordTrig = false, condition = in_mathzone }, t '^{-1}'),
    sa({ trig = 'conj', wordTrig = false, condition = in_mathzone }, t '^{*}'),
    sa({ trig = 'Re', wordTrig = false, condition = in_mathzone }, t [[\mathrm{Re}]]),
    sa({ trig = 'Im', wordTrig = false, condition = in_mathzone }, t [[\mathrm{Im}]]),
    sa({ trig = 'bf', wordTrig = false, condition = in_mathzone }, fmt([[\mathbf{{{}}}]], { i(1) })),
    sa({ trig = 'rm', wordTrig = false, condition = in_mathzone }, fmt([[\mathrm{{{}}}{}]], { i(1), i(2) })),
    sa({ trig = 'trace', wordTrig = false, condition = in_mathzone }, t [[\mathrm{Tr}]]),

    -- ── SYMBOLS ( mA ) ──────────────────────────────────────────────────────────
    sa({ trig = 'ooo', wordTrig = false, condition = in_mathzone }, t [[\infty]]),
    sa({ trig = 'sum', wordTrig = false, condition = in_mathzone }, t [[\sum]]),
    sa({ trig = 'prod', wordTrig = false, condition = in_mathzone }, t [[\prod]]),
    sa({ trig = '+-', wordTrig = false, condition = in_mathzone }, t [[\pm]]),
    sa({ trig = '-+', wordTrig = false, condition = in_mathzone }, t [[\mp]]),
    sa({ trig = '...', wordTrig = false, condition = in_mathzone }, t [[\dots]]),
    sa({ trig = 'nabl', wordTrig = false, condition = in_mathzone }, t [[\nabla]]),
    sa({ trig = 'del', wordTrig = false, condition = in_mathzone }, t [[\nabla]]),
    sa({ trig = 'xx', wordTrig = false, condition = in_mathzone }, t [[\times]]),
    sa({ trig = '**', wordTrig = false, condition = in_mathzone }, fmt([[\cdot {}]], { i(1) })),
    sa({ trig = 'para', wordTrig = false, condition = in_mathzone }, t [[\parallel]]),
    sa({ trig = '===', wordTrig = false, condition = in_mathzone }, t [[\equiv]]),
    sa({ trig = '!=', wordTrig = false, condition = in_mathzone }, t [[\neq]]),
    sa({ trig = '>=', wordTrig = false, condition = in_mathzone }, t [[\geq]]),
    sa({ trig = '<=', wordTrig = false, condition = in_mathzone }, t [[\leq]]),
    sa({ trig = '>>', wordTrig = false, condition = in_mathzone }, t [[\gg]]),
    sa({ trig = '<<', wordTrig = false, condition = in_mathzone }, t [[\ll]]),
    sa({ trig = 'simm', wordTrig = false, condition = in_mathzone }, t [[\sim]]),
    sa({ trig = 'sim=', wordTrig = false, condition = in_mathzone }, t [[\simeq]]),
    sa({ trig = 'prop', wordTrig = false, condition = in_mathzone }, t [[\propto]]),
    sa({ trig = '~~', wordTrig = false, condition = in_mathzone }, t [[\approx]]),

    -- ── ARROWS ( mA ) ────────────────────────────────────────────────────────────
    sa({ trig = '<->', wordTrig = false, condition = in_mathzone }, t [[\leftrightarrow ]]),
    sa({ trig = '->', wordTrig = false, condition = in_mathzone }, t [[\to]]),
    sa({ trig = '!>', wordTrig = false, condition = in_mathzone }, t [[\mapsto]]),
    sa({ trig = '=>', wordTrig = false, condition = in_mathzone }, t [[\implies]]),
    sa({ trig = '=<', wordTrig = false, condition = in_mathzone }, t [[\impliedby]]),

    -- ── SETS / LOGIC ( mA ) ──────────────────────────────────────────────────────
    sa({ trig = 'and', wordTrig = false, condition = in_mathzone }, t [[\cap]]),
    sa({ trig = 'orr', wordTrig = false, condition = in_mathzone }, t [[\cup]]),
    sa({ trig = 'inn', wordTrig = false, condition = in_mathzone }, t [[\in]]),
    sa({ trig = 'notin', wordTrig = false, condition = in_mathzone }, t [[\not\in]]),
    sa({ trig = 'sub=', wordTrig = false, condition = in_mathzone }, t [[\subseteq]]),
    sa({ trig = 'sup=', wordTrig = false, condition = in_mathzone }, t [[\supseteq]]),
    sa({ trig = 'eset', wordTrig = false, condition = in_mathzone }, t [[\emptyset]]),
    sa({ trig = 'set', wordTrig = false, condition = in_mathzone }, fmt([[\{{ {} \}}{}]], { i(1), i(2) })),
    sa({ trig = '&&', wordTrig = false, condition = in_mathzone }, t [[\quad \land \quad]]),
    sa({ trig = 'LL', wordTrig = false, condition = in_mathzone }, t [[\mathcal{L}]]),
    sa({ trig = 'HH', wordTrig = false, condition = in_mathzone }, t [[\mathcal{H}]]),
    sa({ trig = 'CC', wordTrig = false, condition = in_mathzone }, t [[\mathbb{C}]]),
    sa({ trig = 'RR', wordTrig = false, condition = in_mathzone }, t [[\mathbb{R}]]),
    sa({ trig = 'ZZ', wordTrig = false, condition = in_mathzone }, t [[\mathbb{Z}]]),
    sa({ trig = 'NN', wordTrig = false, condition = in_mathzone }, t [[\mathbb{N}]]),
    sa({ trig = 'QQ', wordTrig = false, condition = in_mathzone }, t [[\mathbb{Q}]]),

    -- ── LOGICAL ARGUMENTS ( mA ) ──────────────────────────────────────────────────
    sa({ trig = '?fa', wordTrig = false, condition = in_mathzone }, fmt([[\forall {}]], { i(1) })),
    sa({ trig = '?ex', wordTrig = false, condition = in_mathzone }, fmt([[\exists {}]], { i(1) })),
    sa({ trig = '?tf', wordTrig = false, condition = in_mathzone }, fmt([[\therefore {}]], { i(1) })),
    sa({ trig = '?be', wordTrig = false, condition = in_mathzone }, fmt([[\because {}]], { i(1) })),
    sa({ trig = 'neg', wordTrig = false, condition = in_mathzone }, t [[\neg]]),
    sa({ trig = '?qed', wordTrig = false, condition = in_mathzone }, t [[\square]]),
    sa({ trig = '?st', wordTrig = false, condition = in_mathzone }, t [[\text{ s.t. }]]),
    sa({ trig = '?ue', wordTrig = false, condition = in_mathzone }, fmt([[\exists! {}]], { i(1) })),
    sa({ trig = 'iff', wordTrig = false, condition = in_mathzone }, t [[\iff]]),

    -- ── DECORATORS ( mA, no word boundary ) ──────────────────────────────────────
    -- NOTE: These plain fmt-based decorators are INTENTIONAL fallbacks.
    -- The smart postfix versions below (priority = 2000) use resolveExpandParams to
    -- capture the preceding expression (e.g. "x_1 hat" → "\hat{x_1}"). When the
    -- cursor has no valid preceding expression, resolveExpandParams returns nil and
    -- LuaSnip falls back to the lower-priority snippet here, allowing the user to
    -- type "hat" with no prior expression and get "\hat{}{}" with a fill-in prompt.
    sa({ trig = 'hat', wordTrig = false, condition = in_mathzone }, fmt([[\hat{{{}}}{}]], { i(1), i(2) })),
    sa({ trig = 'bar', wordTrig = false, condition = in_mathzone }, fmt([[\bar{{{}}}{}]], { i(1), i(2) })),
    sa({ trig = 'dot', wordTrig = false, condition = in_mathzone }, fmt([[\dot{{{}}}{}]], { i(1), i(2) })),
    sa({ trig = 'ddot', wordTrig = false, condition = in_mathzone }, fmt([[\ddot{{{}}}{}]], { i(1), i(2) })),
    sa({ trig = 'cdot', wordTrig = false, condition = in_mathzone }, t [[\cdot]]),
    sa({ trig = 'tilde', wordTrig = false, condition = in_mathzone }, fmt([[\tilde{{{}}}{}]], { i(1), i(2) })),
    sa({ trig = 'und', wordTrig = false, condition = in_mathzone }, fmt([[\underline{{{}}}{}]], { i(1), i(2) })),
    sa({ trig = 'vec', wordTrig = false, condition = in_mathzone }, fmt([[\vec{{{}}}{}]], { i(1), i(2) })),
    sa(
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
    sa({ trig = 'xnn', wordTrig = false, condition = in_mathzone }, t 'x_{n}'),
    sa({ trig = 'xjj', wordTrig = false, condition = in_mathzone }, t 'x_{j}'),
    sa({ trig = 'xp1', wordTrig = false, condition = in_mathzone }, t 'x_{n+1}'),
    sa({ trig = 'ynn', wordTrig = false, condition = in_mathzone }, t 'y_{n}'),
    sa({ trig = 'yii', wordTrig = false, condition = in_mathzone }, t 'y_{i}'),
    sa({ trig = 'yjj', wordTrig = false, condition = in_mathzone }, t 'y_{j}'),

    -- ── INTEGRALS / DERIVATIVES ( mA ) ───────────────────────────────────────────
    sa({ trig = 'ddt', wordTrig = false, condition = in_mathzone }, t [[\frac{d}{dt} ]]),
    sa({ trig = 'dint', wordTrig = false, condition = in_mathzone }, fmt([[\int_{{{}}}^{{{}}} {} \, d{} {}]], { i(1, '0'), i(2, '1'), i(3), i(4, 'x'), i(5) })),
    sa({ trig = 'iiint', wordTrig = false, condition = in_mathzone }, t [[\iiint]]),
    sa({ trig = 'iint', wordTrig = false, condition = in_mathzone }, t [[\iint]]),
    sa({ trig = 'oint', wordTrig = false, condition = in_mathzone }, t [[\oint]]),
    sa({ trig = 'oinf', wordTrig = false, condition = in_mathzone }, fmt([[\int_{{0}}^{{\infty}} {} \, d{} {}]], { i(1), i(2, 'x'), i(3) })),
    sa({ trig = 'infi', wordTrig = false, condition = in_mathzone }, fmt([[\int_{{-\infty}}^{{\infty}} {} \, d{} {}]], { i(1), i(2, 'x'), i(3) })),

    -- ── QUANTUM MECHANICS / PHYSICS ( mA ) ───────────────────────────────────────
    sa({ trig = 'dag', wordTrig = false, condition = in_mathzone }, t [[^{\dagger}]]),
    sa({ trig = 'o+', wordTrig = false, condition = in_mathzone }, t [[\oplus ]]),
    sa({ trig = 'ox', wordTrig = false, condition = in_mathzone }, t [[\otimes ]]),
    sa({ trig = 'bra', wordTrig = false, condition = in_mathzone }, fmt([[\bra{{{}}} {}]], { i(1), i(2) })),
    sa({ trig = 'ket', wordTrig = false, condition = in_mathzone }, fmt([[\ket{{{}}} {}]], { i(1), i(2) })),
    sa({ trig = 'brk', wordTrig = false, condition = in_mathzone }, fmt([[\braket{{ {} | {} }} {}]], { i(1), i(2), i(3) })),
    sa({ trig = 'outer', wordTrig = false, condition = in_mathzone }, fmt([[\ket{{{}}} \bra{{{}}} {}]], { i(1, [[\psi]]), rep(1), i(2) })),
    sa({ trig = 'kbt', wordTrig = false, condition = in_mathzone }, t 'k_{B}T'),
    sa({ trig = 'msun', wordTrig = false, condition = in_mathzone }, t [[M_{\odot}]]),

    -- ── CHEMISTRY ( mA ) ─────────────────────────────────────────────────────────
    sa({ trig = 'pu', wordTrig = false, condition = in_mathzone }, fmt([[\pu{{ {} }}]], { i(1) })),
    sa({ trig = 'cee', wordTrig = false, condition = in_mathzone }, fmt([[\ce{{ {} }}]], { i(1) })),
    sa({ trig = 'he4', wordTrig = false, condition = in_mathzone }, t '{}^{4}_{2}He '),
    sa({ trig = 'he3', wordTrig = false, condition = in_mathzone }, t '{}^{3}_{2}He '),
    sa({ trig = 'iso', wordTrig = false, condition = in_mathzone }, fmt('{{}}^{{{}}}_{{{}}}{} ', { i(1, '4'), i(2, '2'), i(3, 'He') })),

    -- ── MATRIX SHORTCUTS ( mA ) ──────────────────────────────────────────────────
    -- Matrix column separator: use double-comma to insert ' & '.
    -- Single comma should remain a literal comma; do not autosnippet it.
    sa({ trig = config.snippets.triggers.matrix_column, wordTrig = false, snippetType = 'autosnippet', condition = in_matrix_env, priority = 2000 }, t(' & ')),

    -- ── ENVIRONMENTS ( mA ) ──────────────────────────────────────────────────────
    sa({ trig = 'pmat', wordTrig = false, condition = in_mathzone }, fmt('\\begin{{pmatrix}}\n{}\n\\end{{pmatrix}}', { i(1) })),
    sa({ trig = 'bmat', wordTrig = false, condition = in_mathzone }, fmt('\\begin{{bmatrix}}\n{}\n\\end{{bmatrix}}', { i(1) })),
    sa({ trig = 'Bmat', wordTrig = false, condition = in_mathzone }, fmt('\\begin{{Bmatrix}}\n{}\n\\end{{Bmatrix}}', { i(1) })),
    sa({ trig = 'vmat', wordTrig = false, condition = in_mathzone }, fmt('\\begin{{vmatrix}}\n{}\n\\end{{vmatrix}}', { i(1) })),
    sa({ trig = 'Vmat', wordTrig = false, condition = in_mathzone }, fmt('\\begin{{Vmatrix}}\n{}\n\\end{{Vmatrix}}', { i(1) })),
    sa({ trig = 'matrix', wordTrig = false, condition = in_mathzone }, fmt('\\begin{{matrix}}\n{}\n\\end{{matrix}}', { i(1) })),
    sa({ trig = 'cases', wordTrig = false, condition = in_mathzone }, fmt('\\begin{{cases}}\n{}\n\\end{{cases}}', { i(1) })),
    sa({ trig = 'align', wordTrig = false, condition = in_mathzone }, fmt('\\begin{{align}}\n{}\n\\end{{align}}', { i(1) })),
    sa({ trig = 'array', wordTrig = false, condition = in_mathzone }, fmt('\\begin{{array}}\n{}\n\\end{{array}}', { i(1) })),

    -- ── BRACKETS ( mA ) ──────────────────────────────────────────────────────────
    sa({ trig = 'avg', wordTrig = false, condition = in_mathzone }, fmt([[\langle {} \rangle {}]], { i(1), i(2) })),
    sa({ trig = 'norm', wordTrig = false, condition = in_mathzone }, fmt([[\lvert {} \rvert {}]], { i(1), i(2) })),
    sa({ trig = 'Norm', wordTrig = false, condition = in_mathzone }, fmt([[\lVert {} \rVert {}]], { i(1), i(2) })),
    sa({ trig = 'ceil', wordTrig = false, condition = in_mathzone }, fmt([[\lceil {} \rceil {}]], { i(1), i(2) })),
    sa({ trig = 'floor', wordTrig = false, condition = in_mathzone }, fmt([[\lfloor {} \rfloor {}]], { i(1), i(2) })),
    sa({ trig = 'mod', wordTrig = false, condition = in_mathzone }, fmt('|{}|{}', { i(1), i(2) })),
    sa(
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
    sa({ trig = 'lr(', wordTrig = false, condition = in_mathzone }, fmt([[\left( {} \right) {}]], { i(1), i(2) })),
    sa({ trig = 'lr{', wordTrig = false, condition = in_mathzone }, fmt([[\left\{{ {} \right\}} {}]], { i(1), i(2) })),
    sa({ trig = 'lr[', wordTrig = false, condition = in_mathzone }, fmt([[\left[ {} \right] {}]], { i(1), i(2) })),
    sa({ trig = 'lr|', wordTrig = false, condition = in_mathzone }, fmt([[\left| {} \right| {}]], { i(1), i(2) })),
    sa({ trig = 'lra', wordTrig = false, condition = in_mathzone }, fmt([[\left< {} \right> {}]], { i(1), i(2) })),

    -- ── SEQUENCES & SERIES ( mA ) ────────────────────────────────────────────────
    sa({ trig = 'seq', wordTrig = false, condition = in_mathzone }, fmt([[\{{{}_{{{} = {}}}\}}^{{\infty}} {}]], { i(1, 'a_n'), i(2, 'n'), i(3, '1'), i(4) })),
    sa({ trig = 'sumn', wordTrig = false, condition = in_mathzone }, fmt([[sum_{{{} = {}}}^{{\infty}} {}]], { i(1, 'n'), i(2, '1'), i(3) })),
    sa({ trig = 'sumk', wordTrig = false, condition = in_mathzone }, fmt([[sum_{{{} = {}}}^{{{}}} {}]], { i(1, 'k'), i(2, '1'), i(3, 'n'), i(4) })),
    sa({ trig = 'limn', wordTrig = false, condition = in_mathzone }, fmt([[\lim_{{{} \to \infty}} {}]], { i(1, 'n'), i(2) })),
    sa({ trig = 'limsup', wordTrig = false, condition = in_mathzone }, fmt([[\limsup_{{{} \to \infty}} {}]], { i(1, 'n'), i(2) })),
    sa({ trig = 'liminf', wordTrig = false, condition = in_mathzone }, fmt([[\liminf_{{{} \to \infty}} {}]], { i(1, 'n'), i(2) })),
    sa({ trig = 'geom', wordTrig = false, condition = in_mathzone }, fmt([[{} \cdot {}^{{{}-1}} {}]], { i(1, 'a'), i(2, 'r'), i(3, 'n'), i(4) })),
    sa({ trig = 'arith', wordTrig = false, condition = in_mathzone }, fmt([[{} + ({} - 1){} {}]], { i(1, 'a'), i(2, 'n'), i(3, 'd'), i(4) })),

    -- ── CUSTOM / MISC ( mA ) ─────────────────────────────────────────────────────
    sa(
      { trig = 'tayl', wordTrig = false, condition = in_mathzone },
      fmt(
        [[{}({} + {}) = {}({}) + {}'({}){}  + {}''({}) \frac{{{}^{{2}}}}{{2!}} + \dots{}]],
        { i(1, 'f'), i(2, 'x'), i(3, 'h'), rep(1), rep(2), rep(1), rep(2), rep(3), rep(1), rep(2), rep(3), i(4) }
      )
    ),

    -- ── TRIG FUNCTIONS ( moved to end to prevent shadowing specific snippets like 'dint' ) ──
    sa(
      { trig = '(.-)(arcsin)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) },
      f(function(_, snip)
        return snip.captures[1] .. [[\arcsin]]
      end)
    ),
    sa(
      { trig = '(.-)(arccos)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) },
      f(function(_, snip)
        return snip.captures[1] .. [[\arccos]]
      end)
    ),
    sa(
      { trig = '(.-)(arctan)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) },
      f(function(_, snip)
        return snip.captures[1] .. [[\arctan]]
      end)
    ),
    sa(
      { trig = '(.-)(sin)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) },
      f(function(_, snip)
        return snip.captures[1] .. [[\sin]]
      end)
    ),
    sa(
      { trig = '(.-)(cos)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) },
      f(function(_, snip)
        return snip.captures[1] .. [[\cos]]
      end)
    ),
    sa(
      { trig = '(.-)(tan)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) },
      f(function(_, snip)
        return snip.captures[1] .. [[\tan]]
      end)
    ),
    sa(
      { trig = '(.-)(csc)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) },
      f(function(_, snip)
        return snip.captures[1] .. [[\csc]]
      end)
    ),
    sa(
      { trig = '(.-)(sec)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) },
      f(function(_, snip)
        return snip.captures[1] .. [[\sec]]
      end)
    ),
    sa(
      { trig = '(.-)(cot)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) },
      f(function(_, snip)
        return snip.captures[1] .. [[\cot]]
      end)
    ),
    -- sa({ trig = '(.-)(sinh)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) }, f(function(_, snip) return snip.captures[1] .. [[\sinh]] end)),
    -- sa({ trig = '(.-)(cosh)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) }, f(function(_, snip) return snip.captures[1] .. [[\cosh]] end)),
    -- sa({ trig = '(.-)(tanh)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) }, f(function(_, snip) return snip.captures[1] .. [[\tanh]] end)),
    sa(
      { trig = '(.-)(exp)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) },
      f(function(_, snip)
        return snip.captures[1] .. [[\exp]]
      end)
    ),
    sa(
      { trig = '(.-)(log)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) },
      f(function(_, snip)
        return snip.captures[1] .. [[\log]]
      end)
    ),
    sa(
      { trig = '(.-)(ln)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) },
      f(function(_, snip)
        return snip.captures[1] .. [[\ln]]
      end)
    ),
    sa(
      { trig = '(.-)(det)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) },
      f(function(_, snip)
        return snip.captures[1] .. [[\det]]
      end)
    ),
    sa(
      { trig = '(.-)(int)', regTrig = true, wordTrig = false, condition = all(in_mathzone, no_prefix) },
      f(function(_, snip)
        return snip.captures[1] .. [[\int]]
      end)
    ),

    -- ── REGEX AUTOSNIPPETS ( mA, no word boundary ) ───────────────────────────────
    -- Auto letter subscript: x2 → x_{2}
    sa(
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
    sa(
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
    sa(
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
    sa(
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
    sa(
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
    sa(
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
    sa(
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
    sa(
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
    sa(
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
    sa(
      { trig = '\\hat{([A-Za-z])}(%d)', regTrig = true, wordTrig = false, condition = in_mathzone },
      f(function(_, snip)
        return [[\hat{]] .. snip.captures[1] .. '}_{' .. snip.captures[2] .. '}'
      end)
    ),
    sa(
      { trig = '\\vec{([A-Za-z])}(%d)', regTrig = true, wordTrig = false, condition = in_mathzone },
      f(function(_, snip)
        return [[\vec{]] .. snip.captures[1] .. '}_{' .. snip.captures[2] .. '}'
      end)
    ),
    sa(
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
    sa({ trig = [[\sum]], wordTrig = false, condition = in_mathzone }, fmt([[\sum_{{{} = {}}}^{{{}}} {}]], { i(1, 'i'), i(2, '1'), i(3, 'N'), i(4) })),
    sa({ trig = [[\prod]], wordTrig = false, condition = in_mathzone }, fmt([[\prod_{{{} = {}}}^{{{}}} {}]], { i(1, 'i'), i(2, '1'), i(3, 'N'), i(4) })),
    sa({ trig = [[\int]], wordTrig = false, condition = in_mathzone }, fmt([[\int {} \, d{} {}]], { i(1), i(2, 'x'), i(3) })),
    sa({ trig = 'lim', wordTrig = false, condition = in_mathzone }, fmt([[\lim_{{ {} \to {} }} {}]], { i(1, 'n'), i(2, [[\infty]]), i(3) })),

    -- Partial derivatives
    sa({ trig = 'par', wordTrig = false, condition = in_mathzone }, fmt([[\frac{{ \partial {} }}{{ \partial {} }} {}]], { i(1, 'y'), i(2, 'x'), i(3) })),
    sa(
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
  -- PIPELINE: disable
  -- (trig overrides are handled at construction time via sa())
  -- ============================================================================
  local function apply_pipeline(snip_list)
    local disable_set = {}
    for _, trig in ipairs(config.snippets.disable or {}) do
      disable_set[trig] = true
    end

    local filtered = {}
    for _, snip in ipairs(snip_list) do
      if not disable_set[snip.trigger] then
        table.insert(filtered, snip)
      end
    end

    return filtered
  end

  -- Apply pipeline (disable filter) to both tables
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
