# latex-tools.nvim: Config Activation, Extensibility & README

## Goal

Three improvements to the extracted latex-tools.nvim plugin:
1. Make the `triggers` config actually drive snippet registration
2. Add snippet override/disable/extra extensibility API
3. Write a README for a Neovim-familiar audience

---

## 1. Snippet Registration Pipeline

### Current State

`M.register(_config)` in `snippets.lua` ignores config entirely. All trigger strings are hardcoded. The four named triggers (`inline_math = 'mk'`, `display_math = 'dm'`, `begin_env = 'beg'`, `matrix_column = ',,'`) exist in `init.lua` defaults but have zero effect.

### New Pipeline

`M.register(config)` builds snippets using config values, then post-processes:

1. **Build** — construct `auto_snippets` and `regular_snippets` using `config.snippets.triggers.*` directly for the 4 named entry points (`mk`/`dm`/`beg`/`,,`). No post-build substitution needed for named triggers.
2. **Apply `overrides`** — walk both tables; for any snippet whose `trig` matches a key in `config.snippets.overrides`, merge the override fields (`trig`, `wordTrig`, `regTrig` only — body/nodes cannot be patched). `extra` snippets are not affected.
3. **Apply `disable`** — filter out snippets whose `trig` is in `config.snippets.disable`. `extra` snippets are not affected.
4. **Append `config.snippets.extra`** — raw LuaSnip snippet objects appended after disables are applied.
5. **Register** with `ls.add_snippets()`

### Config Shape

```lua
require('latex-tools').setup({
  snippets = {
    triggers = {
      inline_math  = 'mk',   -- text → $...$
      display_math = 'dm',   -- text → $$...$$
      begin_env    = 'beg',  -- \begin{...}
      matrix_column = ',,',  -- → ' & ' in matrix
    },

    -- Remap trigger strings for built-in snippets.
    -- Key: existing trigger (exact string, or raw Lua pattern for regTrig snippets).
    -- Value: fields to override in the snippet spec — only trig/wordTrig/regTrig;
    --        does NOT affect snippet body or nodes.
    -- Does not apply to snippets in `extra`.
    overrides = {
      ['@a'] = { trig = 'ga' },   -- remap alpha
      ['//'] = { trig = 'ff' },   -- remap smart fraction
    },

    -- Remove built-in snippets by trigger string. Does not apply to `extra`.
    disable = { 'sr', 'cb' },

    -- Raw LuaSnip snippet objects appended after built-in snippets.
    extra = {
      -- s({ trig = 'mysnip', ... }, fmt('...', {...})),
    },
  },
})
```

### Regex Trigger Note

Snippets using `regTrig = true` are keyed by their raw Lua pattern string
(e.g. `'([A-Za-z])(%d)'` for auto-subscript). Use the exact pattern string as
the override/disable key. This is documented in the README.

---

## 2. Moving `mk` and `dm` into the Plugin

### Motivation

`mk` and `dm` currently live in `dotfiles/nvim/lua/snippets/markdown.lua` with
`is_plain_text` condition. Moving them into the plugin means all 4 named
triggers are configurable from one place.

### Changes

**`context.lua`** gains two new functions:

```lua
--- Check if cursor is in a fenced code block.
--- Tries snippets.utils.in_code_block() via pcall first (dotfiles integration),
--- then falls back to a simple treesitter check, then returns false.
--- @return boolean
function M.is_in_code_block() end

--- Check if cursor is in plain text (not math, not code block).
--- @return boolean
function M.is_plain_text() end
```

**`snippets.lua`** gains `mk` and `dm` autosnippets:

```lua
-- inline math entry (text only, markdown filetype)
s({ trig = config.snippets.triggers.inline_math, wordTrig = false,
    snippetType = 'autosnippet', condition = context.is_plain_text },
  fmt('${}$', { i(1) })),

-- display math entry (text only, markdown filetype)
s({ trig = config.snippets.triggers.display_math, wordTrig = true,
    snippetType = 'autosnippet', condition = context.is_plain_text },
  fmt('$$\n{}\n$$', { i(1) })),
```

These register for `markdown` only (not `tex`).

**`dotfiles/nvim/lua/snippets/markdown.lua`**: remove `mk` and `dm` snippet
definitions (2 snippets). Everything else stays.

---

## 3. README

**Audience**: someone who knows Neovim but hasn't used this plugin.  
**Location**: `latex-tools.nvim/README.md`

### Structure

```
# latex-tools.nvim

Brief: LuaSnip-powered LaTeX math snippets + visual wrappers + matrix editing for Neovim.

## Requirements
- Neovim 0.9+
- LuaSnip
- Treesitter markdown parser (optional — improves math zone detection)

## Installation
How to add to runtimepath with vim.pack / rtp:prepend.
Where to call setup() (inside LuaSnip config, after LuaSnip loads).

## Quick Start
Minimal setup() call. Show 3-4 key snippets with before/after.

## Configuration
Full annotated config table.

## Snippet Reference
Markdown table: Trigger | Expands to | Context
Grouped: Greek, Operators, Symbols, Arrows, Sets/Logic, Decorators,
         Integrals/Derivatives, Physics, Chemistry, Environments,
         Brackets, Sequences, Trig, Matrix

## Customizing Triggers
Short example for overrides, disable, extra.
Note on regex trigger keys.

## Visual Wrappers
5 keymaps, condition (math zone only), how to reconfigure.

## Matrix Editing
Enter behavior (\\), ,, column separator, list of detected environments.
```

The snippet cheatsheet is hand-written (not generated) — ~200 rows in grouped
tables. It lives in the README directly, not a separate file.

---

## Files Changed

| File | Change |
|------|--------|
| `lua/latex-tools/snippets.lua` | Apply pipeline (steps 2-5); add `mk`/`dm` snippets |
| `lua/latex-tools/context.lua` | Add `is_in_code_block()` and `is_plain_text()` |
| `lua/latex-tools/init.lua` | Add `overrides`, `disable`, `extra` to defaults |
| `dotfiles/nvim/lua/snippets/markdown.lua` | Remove `mk` and `dm` snippet definitions |
| `README.md` | Create |

---

## Out of Scope

- `categories` toggles (disable entire groups) — deferred
- Lazy.nvim plugin spec — config uses vim.pack/manual rtp
- `:checkhealth` integration — deferred
- `\text{}` escape for tex files — deferred
