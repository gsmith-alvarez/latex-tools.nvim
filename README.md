# latex-tools.nvim

LuaSnip-powered LaTeX math snippets, visual wrappers, and matrix editing for Neovim.

Designed for writing math in Markdown (Obsidian-style) and `.tex` files.

> **Note:** This plugin was largely written with the assistance of AI (Claude). It works well for its author's use case, but may have rough edges. Use at your own discretion and feel free to open issues.

## Requirements

- Neovim 0.10+
- [LuaSnip](https://github.com/L3MON4D3/LuaSnip)
- Treesitter `markdown` parser (optional — improves math zone detection, falls back to a line scanner)

## Installation

### vim.pack (Neovim 0.12+)

```lua
-- In your pack declaration file:
vim.pack.add('https://github.com/gsmith-alvarez/latex-tools.nvim')
```

For deferred loading (recommended — keeps startup fast):

```lua
vim.pack.add(
  { 'https://github.com/gsmith-alvarez/latex-tools.nvim' },
  { load = function() end }
)
```

Then call `packadd` before your LuaSnip setup runs:

```lua
vim.cmd.packadd 'latex-tools.nvim'
```

### lazy.nvim

```lua
{
  'gsmith-alvarez/latex-tools.nvim',
  dependencies = { 'L3MON4D3/LuaSnip' },
  config = function()
    require('latex-tools').setup()
  end,
}
```

### Manual

```bash
git clone https://github.com/gsmith-alvarez/latex-tools.nvim \
  ~/.config/nvim/pack/plugins/start/latex-tools.nvim
```

### Calling setup()

Call `setup()` **after LuaSnip has loaded**:

```lua
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
| Math zone | `/` | `\frac{expr}{|}` (smart fraction — wraps preceding expr) |
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

    -- (reserved for future use — category filtering not yet implemented)
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
| `align` | `\begin{align}\n\|\n\end{align}` |
| `array` | `\begin{array}\n\|\n\end{array}` |
| `text` | `\text{|}|` |
| `'` | `\text{|}|` (shorthand for `text`) |

### Greek Letters (math zone)

| Trigger | Output | Trigger | Output |
|---------|--------|---------|--------|
| `@a` | `\alpha` | `@b` | `\beta` |
| `@g` | `\gamma` | `@G` | `\Gamma` |
| `@d` | `\delta` | `@D` | `\Delta` |
| `@e` | `\epsilon` | `:e` | `\varepsilon` |
| `@z` | `\zeta` | `@h` | `\eta` |
| `@t` | `\theta` | `@T` | `\Theta` |
| `:t` | `\vartheta` | `@i` | `\iota` |
| `@k` | `\kappa` | `@l` | `\lambda` |
| `@L` | `\Lambda` | `@m` | `\mu` |
| `@n` | `\nu` | `@x` | `\xi` |
| `@X` | `\Xi` | `@p` | `\pi` |
| `@r` | `\rho` | `@s` | `\sigma` |
| `@S` | `\Sigma` | `@u` | `\upsilon` |
| `@U` | `\Upsilon` | `@f` | `\phi` |
| `@F` | `\Phi` | `:f` | `\varphi` |
| `@y` | `\psi` | `@Y` | `\Psi` |
| `@o` | `\omega` | `@O` | `\Omega` |
| `ome` | `\omega` | `Ome` | `\Omega` |

### Operators (math zone)

| Trigger | Output | Notes |
|---------|--------|-------|
| `/` | `\frac{expr}{|}` | Smart: wraps preceding expr as numerator |
| `//` | `\frac{|}{|}` | Plain fraction (fill both manually) |
| `sr` | `^{2}` | Square |
| `cb` | `^{3}` | Cube |
| `rd` | `^{|}` | General superscript |
| `us` | `_{|}` | Subscript |
| `sts` | `_\text{|}` | Text subscript |
| `invs` | `^{-1}` | Inverse |
| `conj` | `^{*}` | Conjugate |
| `sq` | `\sqrt{| |}` | Square root |
| `nsq` | `\sqrt[|]{|}` | nth root |
| `ee` | `e^{ | }` | Exponential |
| `bf` | `\mathbf{|}` | Bold |
| `rm` | `\mathrm{|}` | Roman |
| `Re` | `\mathrm{Re}` | Real part |
| `Im` | `\mathrm{Im}` | Imaginary part |
| `trace` | `\mathrm{Tr}` | Trace |

### Decorators / Postfix (math zone)

These wrap the preceding token. Type `x` then the trigger: `xhat` → `\hat{x}`.

| Trigger | Output |
|---------|--------|
| `hat` | `\hat{...}` |
| `bar` | `\bar{...}` |
| `dot` | `\dot{...}` |
| `ddot` | `\ddot{...}` |
| `tilde` | `\tilde{...}` |
| `und` | `\underline{...}` |
| `vec` | `\vec{...}` |
| `deco` | choice menu: hat/bar/dot/ddot/tilde/vec/underline |

### Auto-subscript (math zone)

These are regex autosnippets — they fire automatically as you type.

| Pattern | Example | Output |
|---------|---------|--------|
| `([A-Za-z])(%d)` | `x2` | `x_{2}` |
| `([A-Za-z])_(%d%d)` | `x_12` | `x_{12}` (two-digit subscript) |

### Symbols (math zone)

| Trigger | Output | Trigger | Output |
|---------|--------|---------|--------|
| `ooo` | `\infty` | `sum` | `\sum` |
| `prod` | `\prod` | `xx` | `\times` |
| `+-` | `\pm` | `-+` | `\mp` |
| `...` | `\dots` | `**` | `\cdot ` |
| `nabl` | `\nabla` | `del` | `\nabla` |
| `para` | `\parallel` | `===` | `\equiv` |
| `!=` | `\neq` | `>=` | `\geq` |
| `<=` | `\leq` | `>>` | `\gg` |
| `<<` | `\ll` | `simm` | `\sim` |
| `sim=` | `\simeq` | `prop` | `\propto` |
| `~~` | `\approx` | `norm` | `\lvert...\rvert` |
| `Norm` | `\lVert...\rVert` | `avg` | `\langle...\rangle` |
| `ceil` | `\lceil...\rceil` | `floor` | `\lfloor...\rfloor` |
| `mod` | `\|...\|` | `inn` | `\in` |
| `notin` | `\not\in` | `dag` | `^\dagger` |
| `o+` | `\oplus` | `ox` | `\otimes` |
| `cdot` | `\cdot` | | |

### Sets / Logic (math zone)

| Trigger | Output | Trigger | Output |
|---------|--------|---------|--------|
| `NN` | `\mathbb{N}` | `ZZ` | `\mathbb{Z}` |
| `QQ` | `\mathbb{Q}` | `RR` | `\mathbb{R}` |
| `CC` | `\mathbb{C}` | `LL` | `\mathcal{L}` |
| `HH` | `\mathcal{H}` | `eset` | `\emptyset` |
| `and` | `\cap` | `orr` | `\cup` |
| `inn` | `\in` | `notin` | `\not\in` |
| `sub=` | `\subseteq` | `sup=` | `\supseteq` |
| `set` | `\{ | \}` | `&&` | `\quad \land \quad` |
| `neg` | `\neg` | `iff` | `\iff` |
| `?fa` | `\forall |` | `?ex` | `\exists |` |
| `?ue` | `\exists! |` | `?tf` | `\therefore |` |
| `?be` | `\because |` | `?qed` | `\square` |
| `?st` | `\text{ s.t. }` | | |

### Brackets (math zone)

| Trigger | Output |
|---------|--------|
| `lr(` | `\left( \| \right)` |
| `lr[` | `\left[ \| \right]` |
| `lr{` | `\left\{ \| \right\}` |
| `lr\|` | `\left\| \| \right\|` |
| `lra` | `\left< \| \right>` |
| `brack` | choice menu: `()`, `[]`, `{}`, `<>`, `\|`, `\|\|` |

### Arrows (math zone)

| Trigger | Output | Trigger | Output |
|---------|--------|---------|--------|
| `->` | `\to` | `!>` | `\mapsto` |
| `=>` | `\implies` | `=<` | `\impliedby` |
| `<->` | `\leftrightarrow` | | |

### Integrals / Derivatives (math zone)

| Trigger | Output | Notes |
|---------|--------|-------|
| `dint` | `\int_{|}^{|} | \, d| |` | Definite integral (auto) |
| `oint` | `\oint` | Contour integral (auto) |
| `oinf` | `\int_{0}^{\infty} | \, d| |` | Zero to infinity (auto) |
| `infi` | `\int_{-\infty}^{\infty} | \, d| |` | Improper integral (auto) |
| `iint` | `\iint` | Double integral (auto) |
| `iiint` | `\iiint` | Triple integral (auto) |
| `ddt` | `\frac{d}{dt} ` | Time derivative (auto) |
| `par` | `\frac{ \partial | }{ \partial | } |` | Partial derivative (tab) |
| `pa`_xy_ | `\frac{ \partial x }{ \partial y }` | Regex: `pa([A-Za-z])([A-Za-z])` (tab) |
| `\int` | `\int | \, d| |` | Integral with measure (tab) |
| `\sum` | `\sum_{|=|}^{|} |` | Sum with limits (tab) |
| `\prod` | `\prod_{|=|}^{|} |` | Product with limits (tab) |
| `lim` | `\lim_{ | \to | } |` | Limit (tab) |

### Physics (math zone)

| Trigger | Output | Trigger | Output |
|---------|--------|---------|--------|
| `kbt` | `k_{B}T` | `msun` | `M_{\odot}` |
| `bra` | `\bra{|} |` | `ket` | `\ket{|} |` |
| `brk` | `\braket{ | \| | } |` | `outer` | `\ket{|} \bra{|} |` |

### Chemistry (math zone)

| Trigger | Output | Notes |
|---------|--------|-------|
| `pu` | `\pu{ | }` | Physical units (`physics` package) |
| `cee` | `\ce{ | }` | Chemical equation (`mhchem` package) |
| `he4` | `{}^{4}_{2}He ` | Helium-4 isotope shorthand |
| `he3` | `{}^{3}_{2}He ` | Helium-3 isotope shorthand |
| `iso` | `{}^{|}_{|}| ` | Generic isotope template |

### Trig Functions (math zone)

These use regex patterns (`(.-)(sin)` etc.) so they expand when you type the bare function name — they also prevent double-prefixing if a `\` is already present.

| Trigger | Output | Trigger | Output |
|---------|--------|---------|--------|
| `sin` | `\sin` | `cos` | `\cos` |
| `tan` | `\tan` | `csc` | `\csc` |
| `sec` | `\sec` | `cot` | `\cot` |
| `arcsin` | `\arcsin` | `arccos` | `\arccos` |
| `arctan` | `\arctan` | `ln` | `\ln` |
| `log` | `\log` | `exp` | `\exp` |
| `det` | `\det` | `int` | `\int` |

> **Note:** `sinh`, `cosh`, and `tanh` are commented out in the source and do **not** expand.

### Sequences / Series (math zone)

| Trigger | Output |
|---------|--------|
| `seq` | `\{a_n\}_{n=1}^{\infty} |` (customisable) |
| `sumn` | `sum_{n=1}^{\infty} |` |
| `sumk` | `sum_{k=1}^{n} |` |
| `limn` | `\lim_{n \to \infty} |` |
| `limsup` | `\limsup_{n \to \infty} |` |
| `liminf` | `\liminf_{n \to \infty} |` |
| `geom` | `a \cdot r^{n-1} |` (geometric term) |
| `arith` | `a + (n - 1)d |` (arithmetic term) |

**Misc subscript shorthands:**

| Trigger | Output | Trigger | Output |
|---------|--------|---------|--------|
| `xnn` | `x_{n}` | `xjj` | `x_{j}` |
| `xp1` | `x_{n+1}` | `ynn` | `y_{n}` |
| `yii` | `y_{i}` | `yjj` | `y_{j}` |

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
      ['//'] = { trig = 'ff' },   -- remap plain fraction (// → ff)
      ['/'] = { trig = 'sf' },    -- remap smart fraction (/ → sf)
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
