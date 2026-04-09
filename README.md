# latex-tools.nvim

LuaSnip-powered LaTeX math snippets, visual wrappers, and matrix editing for Neovim.

Designed for writing math in Markdown (Obsidian-style) and `.tex` files.

## Requirements

- Neovim 0.9+
- [LuaSnip](https://github.com/L3MON4D3/LuaSnip)
- Treesitter `markdown` parser (optional — improves math zone detection, falls back to a line scanner)

## Installation

### Manual / vim.pack

```bash
# Add the plugin to your pack directory
mkdir -p ~/.config/nvim/pack/plugins/start
git clone https://github.com/yourname/latex-tools.nvim \
  ~/.config/nvim/pack/plugins/start/latex-tools.nvim
```

Or with `rtp:prepend` from your Lua config:

```lua
vim.opt.rtp:prepend(vim.fn.expand('~/path/to/latex-tools.nvim'))
```

### Calling setup()

Call `setup()` **inside your LuaSnip configuration**, after LuaSnip has loaded:

```lua
-- In your LuaSnip config block:
require('latex-tools').setup()
```

## Quick Start

With default config, these snippets fire automatically:

| In | Type | Result |
|----|------|--------|
| Plain text | `mk` | `$|$` (inline math) |
| Plain text | `dm` | `$$\n\|\n$$` (display math) |
| Math zone | `beg` | `\begin{|}\n\n\end{|}` |
| Math zone | `@a` | `\alpha` |
| Math zone | `//` | `\frac{|}{|}` (smart fraction) |
| Math zone | `xhat` | `\hat{x}` (smart postfix) |
| Matrix env | `,,` | ` & ` (column separator) |

## Configuration

Full config with defaults:

```lua
require('latex-tools').setup({
  snippets = {
    enabled = true,

    -- Trigger strings for the four named entry points.
    triggers = {
      inline_math   = 'mk',   -- plain text → $...$
      display_math  = 'dm',   -- plain text → $$...$$
      begin_env     = 'beg',  -- math zone → \begin{...}
      matrix_column = ',,',   -- matrix env → ' & '
    },

    -- Remap trigger strings for any built-in snippet.
    -- Key: existing trigger (exact string for plain triggers,
    --      raw Lua pattern for regTrig snippets — see below).
    -- Value: fields to replace. Only trig/wordTrig/regTrig can change;
    --        snippet body and nodes cannot be patched.
    -- Does not apply to snippets in `extra`.
    overrides = {},

    -- Remove built-in snippets by trigger string.
    -- Does not apply to snippets in `extra`.
    disable = {},

    -- Raw LuaSnip snippet objects appended after all built-in snippets.
    extra = {},
  },

  visual_wrappers = {
    enabled = true,
    keymaps = {
      underbrace = '<leader>nu',
      overbrace  = '<leader>no',
      cancel     = '<leader>nc',
      cancelto   = '<leader>nk',
      underset   = '<leader>nb',
    },
  },

  matrix = {
    enabled = true,
    enter_inserts_row_sep = true,
    envs = {
      'matrix', 'pmatrix', 'bmatrix', 'Bmatrix',
      'vmatrix', 'Vmatrix', 'smallmatrix',
      'array', 'align', 'align*', 'aligned',
      'cases', 'split', 'gather', 'gather*',
      'gathered', 'eqnarray', 'eqnarray*',
      'multline', 'multline*',
    },
  },

  context = {
    use_treesitter = true,
  },
})
```

## Snippet Reference

Snippets fire in **math zones** (inside `$...$`, `$$...$$`, or any `.tex` file) unless marked **text** (plain text only).

### Math Entry (text zone)

| Trigger | Expands to | Notes |
|---------|-----------|-------|
| `mk` | `$\|$` | Inline math |
| `dm` | `$$\n\|\n$$` | Display math |

### Environments (math zone)

| Trigger | Expands to |
|---------|-----------|
| `beg` | `\begin{|}\n\n\end{|}` |
| `pmat` | `\begin{pmatrix}\n\|\n\end{pmatrix}` |
| `bmat` | `\begin{bmatrix}\n\|\n\end{bmatrix}` |
| `Bmat` | `\begin{Bmatrix}\n\|\n\end{Bmatrix}` |
| `vmat` | `\begin{vmatrix}\n\|\n\end{vmatrix}` |
| `Vmat` | `\begin{Vmatrix}\n\|\n\end{Vmatrix}` |
| `matrix` | `\begin{matrix}\n\|\n\end{matrix}` |
| `cases` | `\begin{cases}\n\|\n\end{cases}` |
| `ali` | `\begin{align}\n\|\n\end{align}` |

### Greek Letters (math zone)

| Trigger | Output | Trigger | Output |
|---------|--------|---------|--------|
| `@a` | `\alpha` | `@b` | `\beta` |
| `@g` | `\gamma` | `@G` | `\Gamma` |
| `@d` | `\delta` | `@D` | `\Delta` |
| `@e` | `\epsilon` | `:e` | `\varepsilon` |
| `@z` | `\zeta` | `@h` | `\eta` |
| `@q` | `\theta` | `@Q` | `\Theta` |
| `:q` | `\vartheta` | `@i` | `\iota` |
| `@k` | `\kappa` | `@l` | `\lambda` |
| `@L` | `\Lambda` | `@m` | `\mu` |
| `@n` | `\nu` | `@x` | `\xi` |
| `@X` | `\Xi` | `@p` | `\pi` |
| `@P` | `\Pi` | `:p` | `\varpi` |
| `@r` | `\rho` | `:r` | `\varrho` |
| `@s` | `\sigma` | `@S` | `\Sigma` |
| `:s` | `\varsigma` | `@t` | `\tau` |
| `@u` | `\upsilon` | `@U` | `\Upsilon` |
| `@f` | `\phi` | `@F` | `\Phi` |
| `:f` | `\varphi` | `@c` | `\chi` |
| `@y` | `\psi` | `@Y` | `\Psi` |
| `@w` | `\omega` | `@W` | `\Omega` |

### Operators (math zone)

| Trigger | Output | Notes |
|---------|--------|-------|
| `//` | `\frac{|}{|}` | Smart: wraps preceding expr |
| `sr` | `^{2}` | Square |
| `cb` | `^{3}` | Cube |
| `rd` | `^{|}` | General superscript |
| `__` | `_{|}` | Subscript |
| `invs` | `^{-1}` | Inverse |
| `compl` | `^{c}` | Complement |
| `td` | `^{|}` | Power |
| `sq` | `\sqrt{|}` | Square root |

### Decorators / Postfix (math zone)

These wrap the preceding token. Type `x` then the trigger: `xhat` → `\hat{x}`.

| Trigger | Output |
|---------|--------|
| `hat` | `\hat{...}` |
| `bar` | `\overline{...}` |
| `dot` | `\dot{...}` |
| `ddot` | `\ddot{...}` |
| `tilde` | `\tilde{...}` |
| `und` | `\underline{...}` |
| `vec` | `\vec{...}` |

### Auto-subscript / Superscript (math zone)

| Pattern | Example | Output |
|---------|---------|--------|
| `letter digit` | `x2` | `x_{2}` |
| `letter letter digit` | `xa2` | `xa_{2}` (subscript on 2-char var) |
| `letter^digit` | `x^2` → auto | `x^{2}` |

### Symbols (math zone)

| Trigger | Output | Trigger | Output |
|---------|--------|---------|--------|
| `ooo` | `\infty` | `sum` | `\sum` |
| `prod` | `\prod` | `lim` | `\lim` |
| `pm` | `\pm` | `mp` | `\mp` |
| `...` | `\ldots` | `c..` | `\cdots` |
| `::` | `\vdots` | `::` | `\ddots` |
| `xx` | `\times` | `**` | `\cdot` |
| `norm` | `\|...\|` | `abs` | `\|...\|` |
| `inn` | `\in` | `notin` | `\notin` |
| `\\\\` | `\setminus` | `sub` | `\subset` |
| `sube` | `\subseteq` | `sup` | `\supset` |
| `supe` | `\supseteq` | `EE` | `\exists` |
| `AA` | `\forall` | `!>` | `\mapsto` |
| `->` | `\to` | `=>` | `\implies` |
| `=<` | `\impliedby` | `iff` | `\iff` |

### Sets / Logic (math zone)

| Trigger | Output | Trigger | Output |
|---------|--------|---------|--------|
| `NN` | `\mathbb{N}` | `ZZ` | `\mathbb{Z}` |
| `QQ` | `\mathbb{Q}` | `RR` | `\mathbb{R}` |
| `CC` | `\mathbb{C}` | `FF` | `\mathbb{F}` |
| `HH` | `\mathbb{H}` | `OO` | `\emptyset` |
| `UU` | `\cup` | `IU` | `\bigcup` |
| `NN` | `\cap` | `IN` | `\bigcap` |

### Brackets (math zone)

| Trigger | Output |
|---------|--------|
| `lr(` | `\left( \| \right)` |
| `lr[` | `\left[ \| \right]` |
| `lrv` | `\left\| \| \right\|` |
| `lrn` | `\left\lVert \| \right\rVert` |
| `lrb` | `\left\{ \| \right\}` |
| `lra` | `\left< \| \right>` |

### Arrows (math zone)

| Trigger | Output | Trigger | Output |
|---------|--------|---------|--------|
| `->` | `\to` | `!>` | `\mapsto` |
| `=>` | `\implies` | `=<` | `\impliedby` |
| `iff` | `\iff` | `upar` | `\uparrow` |
| `dnar` | `\downarrow` | `<->` | `\leftrightarrow` |

### Integrals / Derivatives (math zone)

| Trigger | Output |
|---------|--------|
| `\int` | `\int \| \, d\|` |
| `dint` | `\int_{|}^{|} \| \, d\|` |
| `oint` | `\oint` |
| `par` | `\frac{\partial \|}{\partial \|}` |
| `pa([A-Za-z])([A-Za-z])` | `\frac{\partial #1}{\partial #2}` (regex) |
| `\sum` | `\sum_{\|=\|}^{\|} \|` |
| `\prod` | `\prod_{\|=\|}^{\|} \|` |
| `\lim` | `\lim_{\| \to \|} \|` |

### Physics (math zone)

| Trigger | Output | Trigger | Output |
|---------|--------|---------|--------|
| `kbt` | `k_B T` | `hbar` | `\hbar` |
| `bra` | `\bra{|}` | `ket` | `\ket{|}` |
| `brk` | `\braket{\|\|}` | `outp` | `\ketbra{\|\|}` |

### Chemistry (math zone)

| Pattern | Example | Output |
|---------|---------|--------|
| `([A-Z][a-z]?)([0-9]+)` | `H2O` | `H_2O` (auto-subscript elements) |
| Isotope pattern | `He iso` | `{}^{4}_{2}He` |

### Trig Functions (math zone)

| Trigger | Output | Trigger | Output |
|---------|--------|---------|--------|
| `sin` | `\sin` | `cos` | `\cos` |
| `tan` | `\tan` | `csc` | `\csc` |
| `sec` | `\sec` | `cot` | `\cot` |
| `asin` | `\arcsin` | `acos` | `\arccos` |
| `atan` | `\arctan` | `sinh` | `\sinh` |
| `cosh` | `\cosh` | `tanh` | `\tanh` |
| `ln` | `\ln` | `log` | `\log` |
| `exp` | `\exp` | `perp` | `\perp` |

### Sequences / Series (math zone)

| Trigger | Output |
|---------|--------|
| `x1n` | `x_1, \ldots, x_n` |
| `xin` | `x_i, \ldots, x_n` |
| `x1N` | `x_1, \ldots, x_N` |

### Matrix Editing (matrix env)

| Trigger | Output |
|---------|--------|
| `,,` | ` & ` (column separator) |

## Customizing Triggers

### Remap a built-in trigger

```lua
require('latex-tools').setup({
  snippets = {
    overrides = {
      ['@a'] = { trig = 'ga' },   -- remap alpha: type 'ga' instead of '@a'
      ['//'] = { trig = 'ff' },   -- remap smart fraction
    },
  },
})
```

Only `trig`, `wordTrig`, and `regTrig` can be changed. Snippet body and nodes are fixed.

### Disable a built-in snippet

```lua
require('latex-tools').setup({
  snippets = {
    disable = { 'sr', 'cb' },  -- remove 'square' and 'cube' autosnippets
  },
})
```

### Regex trigger keys

Snippets that use `regTrig = true` are keyed by their raw Lua pattern string. Check the snippet source to find the exact pattern. Examples:

- Auto-subscript: `'([A-Za-z])(%d)'`
- Partial derivative: `'pa([A-Za-z])([A-Za-z])'`

```lua
overrides = {
  ['([A-Za-z])(%d)'] = { trig = '([A-Za-z])_(%d)', regTrig = true },
},
```

### Add custom snippets

```lua
local ls = require 'luasnip'
local s, i, t = ls.snippet, ls.insert_node, ls.text_node

require('latex-tools').setup({
  snippets = {
    extra = {
      s({ trig = 'myv', wordTrig = false }, t [[\mathbf{v}]]),
    },
  },
})
```

`extra` snippets are appended after all built-ins and are not affected by `overrides` or `disable`.

## Visual Wrappers

Five keymaps wrap a visual selection with a LaTeX annotation command. They only fire when the selection is inside a math zone.

| Default keymap | Wraps selection with |
|---------------|---------------------|
| `<leader>nu` | `\underbrace{...}_{}` |
| `<leader>no` | `\overbrace{...}^{}` |
| `<leader>nc` | `\cancel{...}` |
| `<leader>nk` | `\cancelto{}{...}` |
| `<leader>nb` | `\underset{}{...}` |

Use visual mode (`v` or `V`), select the expression, then press the keymap.

To reconfigure:

```lua
require('latex-tools').setup({
  visual_wrappers = {
    keymaps = {
      underbrace = '<leader>wu',
      overbrace  = '<leader>wo',
      cancel     = '<leader>wc',
      cancelto   = '<leader>wk',
      underset   = '<leader>wb',
    },
  },
})
```

## Matrix Editing

Inside any matrix-like environment (`pmatrix`, `bmatrix`, `align`, `cases`, etc.):

- Press `Enter` to insert ` \\ ` (row separator) and start a new line
- Type `,,` to insert ` & ` (column separator)

The Enter behavior integrates with `autolist.nvim` if present; otherwise it sets a standalone `<CR>` keymap inside matrix environments.

Supported environments: `matrix`, `pmatrix`, `bmatrix`, `Bmatrix`, `vmatrix`, `Vmatrix`, `smallmatrix`, `array`, `align`, `align*`, `aligned`, `cases`, `split`, `gather`, `gather*`, `gathered`, `eqnarray`, `eqnarray*`, `multline`, `multline*`.

To add environments:

```lua
require('latex-tools').setup({
  matrix = {
    envs = {
      -- (replaces the default list entirely — include defaults if needed)
      'matrix', 'pmatrix', 'bmatrix',
      'myenv',   -- custom environment
    },
  },
})
```
