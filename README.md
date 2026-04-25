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
| Plain text | `mk` | `$·$` (inline math) |
| Plain text | `dm` | `$$\n·\n$$` (display math) |
| Math zone | `beg` | `\begin{·}\n\n\end{·}` |
| Math zone | `@a` | `\alpha` |
| Math zone | `/` | `\frac{expr}{·}` (smart fraction — wraps preceding expr) |
| Math zone | `xhat` | `\hat{x}` (smart postfix) |
| Math zone | `3*3pmat` | 3×3 `pmatrix` with a tab stop in every cell (dynamic matrix) |
| Matrix env | `,,` | ` & ` (column separator) |

## Configuration

Full config with defaults:

```lua
require('latex-tools').setup({
  snippets = {
    enabled = true,

    -- Filetypes to register snippets into.
    -- For a Markdown-first workflow, set { 'markdown' }.
    filetypes = { 'markdown', 'tex' },

    -- Trigger strings for the four named entry points.
    triggers = {
      inline_math   = 'mk',   -- plain text → $...$
      display_math  = 'dm',   -- plain text → $$...$$
      begin_env     = 'beg',  -- math zone → \begin{...}
      matrix_column = ',,',   -- matrix env → ' & '
    },

    -- Built-in snippet buckets: set a key to false to drop that whole group (see "Snippet categories" below).
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
      underbrace = '<leader>lu',
      overbrace  = '<leader>lo',
      cancel     = '<leader>lc',
      cancelto   = '<leader>lk',
      underset   = '<leader>lb',
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

### Snippet categories

`snippets.categories` groups triggers into buckets. Set a key to **`false`** to omit every snippet in that bucket (see `category_for_trigger()` in `lua/latex-tools/snippets.lua`). Omitting a key keeps the default (**enabled**).

Notable **`matrices`** snippets: the dynamic matrix pattern `(%d+)%*(%d+)([bBpvV])mat`, the matrix-column trigger (default `,,`), and **`&=`** (align row operator). **`environments`** is separate: bare `pmat`, `bmat`, `matrix`, etc.

## Snippet Reference

Snippets fire in **math zones** (inside `$...$`, `$$...$$`, or any `.tex` file) unless marked **text** (plain text only).

`·` in expansion output marks one **LuaSnip insert / tab stop** in left-to-right order. When you see **`· ·` in a row** (two dots with only spaces or punctuation between them), that is **two different stops**, not one stop drawn twice: you tab through the first, then the second. For many big snippets the **last** stop is a deliberate “jump out” past the closing brace or past the main symbol so you can keep typing without the snippet feeling boxed in.

Many enclosing snippets (environments, fractions, `\mathbf`, smart postfix decorators, dynamic matrices, and similar) also include that **final** jump-out stop after the closing delimiter or outside the fence.

### Visual selection defaults

Some snippets will use the current visual selection as their default content (via `LS_SELECT_RAW`) when expanded from a visual-mode snippet workflow. This currently applies to:

- `text` / `'` (`\text{...}`)
- `box` (`\boxed{...}`)
- fallback decorator forms (`hat`, `bar`, `dot`, `ddot`, `tilde`, `und`, `vec`, `mfr`)

### Math Entry (text zone)

| Trigger | Expands to | Notes |
|---------|-----------|-------|
| `mk` | `$·$·` | Inline math |
| `dm` | `$$\n·\n$$ ·` | Display math |

### Environments (math zone)

| Trigger | Expands to |
|---------|-----------|
| `beg` | `\begin{·}\n·\n\end{·}·` |
| `pmat` | `\begin{pmatrix}\n·\n\end{pmatrix}·` |
| `bmat` | `\begin{bmatrix}\n·\n\end{bmatrix}·` |
| `Bmat` | `\begin{Bmatrix}\n·\n\end{Bmatrix}·` |
| `vmat` | `\begin{vmatrix}\n·\n\end{vmatrix}·` |
| `Vmat` | `\begin{Vmatrix}\n·\n\end{Vmatrix}·` |
| `matrix` | `\begin{matrix}\n·\n\end{matrix}·` |
| `cases` | `\begin{cases}\n·\n\end{cases}·` |
| `align` | `\begin{align}\n·\n\end{align}·` |
| `array` | `\begin{array}\n·\n\end{array}·` |
| `box` | `\boxed{·}·` |
| `subst` | `\substack{·}·` |
| `text` | `\text{·}·` |
| `'` | `\text{·}·` (shorthand for `text`) |

Prefilled **b** / **B** / **p** / **v** / **V** matrices with a tab stop in every cell use the separate **dynamic matrix** autosnippet (`N*M` + type + `mat`, e.g. `3*3pmat`); see [Matrix Editing](#matrix-editing-matrix-env).

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

Full Greek names also auto-expand (word boundary required):

| Trigger | Output | Trigger | Output |
|---------|--------|---------|--------|
| `alpha` | `\alpha` | `beta` | `\beta` |
| `gamma` | `\gamma` | `Gamma` | `\Gamma` |
| `delta` | `\delta` | `Delta` | `\Delta` |
| `epsilon` | `\epsilon` | `varepsilon` | `\varepsilon` |
| `zeta` | `\zeta` | `eta` | `\eta` |
| `theta` | `\theta` | `Theta` | `\Theta` |
| `vartheta` | `\vartheta` | `iota` | `\iota` |
| `kappa` | `\kappa` | `lambda` | `\lambda` |
| `Lambda` | `\Lambda` | `mu` | `\mu` |
| `nu` | `\nu` | `xi` | `\xi` |
| `Xi` | `\Xi` | `pi` | `\pi` |
| `rho` | `\rho` | `sigma` | `\sigma` |
| `Sigma` | `\Sigma` | `upsilon` | `\upsilon` |
| `Upsilon` | `\Upsilon` | `phi` | `\phi` |
| `varphi` | `\varphi` | `Phi` | `\Phi` |
| `psi` | `\psi` | `Psi` | `\Psi` |
| `omega` | `\omega` | `Omega` | `\Omega` |
| `chi` | `\chi` | `tau` | `\tau` |

### Operators (math zone)

| Trigger | Output | Notes |
|---------|--------|-------|
| `/` | `\frac{expr}{·}·` | Smart: wraps preceding expr as numerator |
| `cfr` | `\cfrac{·}{·} ·` | Continued fraction |
| `sr` | `^{2}` | Square |
| `cb` | `^{3}` | Cube |
| `rd` | `^{·}` | General superscript |
| `us` | `_{·}` | Subscript |
| `sts` | `_\text{·}·` | Text subscript |
| `invs` | `^{-1}` | Inverse |
| `conj` | `^{*}` | Conjugate |
| `compl` | `^{c}` | Set complement |
| `trans` | `^{T}` | Transpose |
| `sq` | `\sqrt{· ·}` | Square root |
| `nsq` | `\sqrt[·]{·}` | nth root |
| `ee` | `e^{ · }` | Exponential |
| `bf` | `\mathbf{·}·` | Bold |
| `rm` | `\mathrm{·}` | Roman |
| `Re` | `\mathrm{Re}` | Real part |
| `Im` | `\mathrm{Im}` | Imaginary part |
| `trace` | `\mathrm{Tr}` | Trace |

### Decorators / Postfix (math zone)

These wrap the preceding token. Type `x` then the trigger: `xhat` → `\hat{x}`. The high-priority postfix variants include a trailing tab stop after the command.

| Trigger | Output |
|---------|--------|
| `hat` | `\hat{...}·` |
| `bar` | `\bar{...}·` |
| `dot` | `\dot{...}·` |
| `ddot` | `\ddot{...}·` |
| `tilde` | `\tilde{...}·` |
| `und` | `\underline{...}·` |
| `vec` | `\vec{...}·` |
| `mfr` | `\mathfrak{...}·` |
| `deco` | choice menu: hat/bar/dot/ddot/tilde/vec/underline (then a trailing tab past the brace) |

### Auto-subscript (math zone)

These are regex autosnippets — they fire automatically as you type.

| Pattern | Example | Output |
|---------|---------|--------|
| `([A-Za-z])(%d)` | `x2` | `x_{2}` |
| `([A-Za-z])_(%d%d)` | `x_12` | `x_{12}` (two-digit subscript) |

That is why the **dynamic matrix** trigger uses an asterisk between dimensions (`3*3pmat`), not `3x3…`: a middle `x` would match as a letter before a digit and expand too early (see [Matrix Editing](#matrix-editing-matrix-env)).

### Symbols (math zone)

| Trigger | Output | Trigger | Output |
|---------|--------|---------|--------|
| `ooo` | `\infty` | `sum` | `\sum` |
| `prod` | `\prod` | `xx` | `\times` |
| `+-` | `\pm` | `-+` | `\mp` |
| `...` | `\dots` | `**` | `\cdot ` |
| `nabl` | `\nabla` | `del` | `\nabla` |
| `pll` | `\parallel` | `===` | `\equiv` |
| `!=` | `\neq` | `>=` | `\geq` |
| `<=` | `\leq` | `>>` | `\gg` |
| `<<` | `\ll` | `simm` | `\sim` |
| `sim=` | `\simeq` | `prop` | `\propto` |
| `~~` | `\approx` | `-~` | `\backsimeq` |
| `=~` | `\cong` | `:=` | `\coloneqq` |
| `dp` | `\partial` | `lll` | `\ell` |
| `::` | `\colon` | `perp` | `\perp` |
| `upar` | `\uparrow` | `dnar` | `\downarrow` |
| `norm` | `\lvert...\rvert` | `Norm` | `\lVert...\rVert` |
| `avg` | `\langle...\rangle` | `ceil` | `\lceil...\rceil` |
| `floor` | `\lfloor...\rfloor` | `mod` | `\|...\|` |
| `inn` | `\in` | `notin` | `\not\in` |
| `dag` | `^\dagger` | `o+` | `\oplus` |
| `ox` | `\otimes` | `cdot` | `\cdot` |

### Sets / Logic (math zone)

| Trigger | Output | Trigger | Output |
|---------|--------|---------|--------|
| `NN` | `\mathbb{N}` | `ZZ` | `\mathbb{Z}` |
| `QQ` | `\mathbb{Q}` | `RR` | `\mathbb{R}` |
| `CC` | `\mathbb{C}` | `PP` | `\mathbb{P}` |
| `HH` | `\mathbb{H}` | `II` | `\mathbb{·}·` |
| `LL` | `\mathcal{L}` | `eset` | `\emptyset` |
| `and` | `\cap` | `orr` | `\cup` |
| `cc` | `\subset` | `qq` | `\supset` |
| `sub=` | `\subseteq` | `sup=` | `\supseteq` |
| `AND` | `\bigcap` | `CUP` | `\bigcup` |
| `setm` | `\setminus` | `inn` | `\in` |
| `notin` | `\not\in` | `VV` | `\lor` |
| `WW` | `\land` | `!W` | `\bigwedge` |
| `&&` | `\quad \land \quad` | `neg` | `\neg` |
| `iff` | `\iff` | `AA` | `\forall` |
| `EE` | `\exists` | `?fa` | `\forall ·` |
| `?ex` | `\exists ·` | `?ue` | `\exists! ·` |
| `?tf` | `\therefore ·` | `?be` | `\because ·` |
| `?qed` | `\square` | `?st` | `\text{ s.t. }` |

`set` — choice node with three forms:

| Choice | Output |
|--------|--------|
| 1 (default) | `\{x\}` |
| 2 | `\{x \mid y\}` |
| 3 | `\{x \colon y\}` |

### Brackets (math zone)

| Trigger | Output |
|---------|--------|
| `lr(` | `\left( · \right)` |
| `lr[` | `\left[ · \right]` |
| `lr{` | `\left\{ · \right\}` |
| `lr\|` | `\left\| · \right\|` |
| `lra` | `\left< · \right>` |
| `binom` | `\binom{·}{·}` |
| `brack` | choice menu: `()`, `[]`, `{}`, `<>`, `\|`, `\|\|` (then a trailing tab past the pair) |

### Arrows (math zone)

| Trigger | Output | Trigger | Output |
|---------|--------|---------|--------|
| `->` | `\to` | `!>` | `\mapsto` |
| `=>` | `\implies` | `=<` | `\impliedby` |
| `<->` | `\leftrightarrow` | `-->` | `\longrightarrow` |

Extensible arrows:

| Trigger | Output |
|---------|--------|
| `xra` | `\xrightarrow{·}{·} ·` (choice: optional `[bottom]`, then trailing tab) |
| `xla` | `\xleftarrow{·}{·} ·` (choice: optional `[bottom]`, then trailing tab) |

### Integrals / Derivatives (math zone)

| Trigger | Output | Notes |
|---------|--------|-------|
| `dint` | `\int_{·}^{·} · \, d· ·` | Definite integral (auto) |
| `oint` | `\oint` | Contour integral (auto) |
| `oinf` | `\int_{0}^{\infty} · \, d· ·` | Zero to infinity (auto) |
| `infi` | `\int_{-\infty}^{\infty} · \, d· ·` | Improper integral (auto) |
| `iint` | `\iint` | Double integral (auto) |
| `iiint` | `\iiint` | Triple integral (auto) |
| `ddt` | `\frac{d}{dt} ·` | Time derivative (auto) |
| `par` | `\frac{ \partial · }{ \partial · } · ·` | Partial derivative (**auto** in math; `wordTrig` + skips `\par…` for `\partial`) |
| `\int` | `\int · \, d· · ·` | Integral with measure (tab) |
| `\lim` | `\lim_{· \to ·} · ·` | After typing `\lim`, Tab for limits (defaults `n`, `\infty`) |
| `\sum` | `\sum_{·=·}^{·} · ·` | Sum with limits (tab) |
| `\prod` | `\prod_{·=·}^{·} · ·` | Product with limits (tab) |

`par` expands as soon as you finish the three letters. That means identifiers that **start** with `par` (e.g. `parent`, `parity`) will expand after `par` unless you split typing (e.g. insert a space and delete it). The old `\parallel` trigger `para` was renamed to **`pll`** so it does not collide with `par`.

### Align helpers (align/aligned/eqnarray only)

| Trigger | Output |
|---------|--------|
| `itr` | `\intertext{...}` |
| `tag` | `\tag{...}` |
| `ntg` | `\notag` |
| `br` | `\\` followed by a newline |

### Physics (math zone)

| Trigger | Output | Trigger | Output |
|---------|--------|---------|--------|
| `kbt` | `k_{B}T` | `msun` | `M_{\odot}` |
| `bra` | `\bra{·} ·` | `ket` | `\ket{·} ·` |
| `brk` | `\braket{ · \| · } ·` | `outer` | `\ket{·} \bra{·} · ·` |

### Chemistry (math zone)

| Trigger | Output | Notes |
|---------|--------|-------|
| `pu` | `\pu{ · }·` | Physical units (`physics` package) |
| `cee` | `\ce{ · }·` | Chemical equation (`mhchem` package) |
| `he4` | `{}^{4}_{2}He ` | Helium-4 isotope shorthand |
| `he3` | `{}^{3}_{2}He ` | Helium-3 isotope shorthand |
| `iso` | `{}^{·}_{·}· ·` | Generic isotope template |

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
| `max` | `\max` | `min` | `\min` |
| `sup` | `\sup` | `inf` | `\inf` |
| `deg` | `\deg` | `argmax` | `\argmax` |
| `argmin` | `\argmin` | | |

> **Note:** `sinh`, `cosh`, and `tanh` are commented out in the source and do **not** expand.

### Sequences / Series (math zone)

| Trigger | Output |
|---------|--------|
| `seq` | `\{a_n\}_{n=1}^{\infty} ·` (customisable) |
| `sumn` | `sum_{n=1}^{\infty} ·` |
| `sumk` | `sum_{k=1}^{n} ·` |
| `lim` | `\lim` | Auto (text only); then **Tab** on `\lim` for the regular `_{·\to·}` snippet (like `\int` + Tab) |
| `geom` | `a \cdot r^{n-1} ·` (geometric term) |
| `arith` | `a + (n - 1)d ·` (arithmetic term) |

**Limit (two steps, like integral):** **`lim`** (auto) inserts plain **`\lim`** (no inner tab stops). For **`_{n \to \infty}`** (editable), press **Tab** with the cursor on **`\lim`** to expand the **regular** snippet **`\lim_{· \to ·} · ·`** (same idea as **`\int`** then Tab for **`\int … \, d· …`**).

If you type **`\lim`** yourself (backslash then `lim`), the **`lim`** autosnippet does **not** run on the `lim` suffix, so you never get **`\\lim`** from that overlap.

**Misc subscript shorthands:**

| Trigger | Output | Trigger | Output |
|---------|--------|---------|--------|
| `xnn` | `x_{n}` | `xjj` | `x_{j}` |
| `xp1` | `x_{n+1}` | `ynn` | `y_{n}` |
| `yii` | `y_{i}` | `yjj` | `y_{j}` |

### Matrix Editing (matrix env)

| Trigger | Output | Condition |
|---------|--------|-----------|
| `,,` | ` & ` | Any matrix/tabular env |
| `&=` | `&= ·  \\` (choice: `&=` / `&\leq` / `&\geq`) | align/aligned/eqnarray only |

**Dynamic matrix** (autosnippet in math):

Type `<rows>*<cols><type>mat` (asterisk between the numbers). An `x` separator would collide with **letter+digit** auto-subscript (`x3` → `x_{3}`) while you type something like `3x3pmat`.

This order keeps a bare `<type>mat` from winning first (e.g. `pmat` still expands to an empty `pmatrix` shell).

| Example trigger | Result |
|-----------------|--------|
| `3*3pmat` | 3×3 `pmatrix` |
| `2*4bmat` | 2×4 `bmatrix` |
| `4*4Vmat` | 4×4 `Vmatrix` |

Valid type letters: `b`, `B`, `p`, `v`, `V` (maps to `b/B/p/v/Vmatrix`).

The snippet expands automatically when the pattern is complete. Tab visits every cell in row-major order. The last cell has no trailing `\\`. One more tab after `\end{…matrix}` jumps past the environment.

## Customizing Triggers

### Remap a built-in trigger

```lua
require('latex-tools').setup({
  snippets = {
    overrides = {
      ['@a'] = { trig = 'ga' },   -- remap alpha: type 'ga' instead of '@a'
      ['/'] = { trig = 'sf' },    -- remap smart fraction (/ → sf)
    },
  },
})
```

Only `trig`, `wordTrig`, and `regTrig` can be changed. Snippet body and nodes are fixed. The `\parallel` trigger is **`pll`** so it does not collide with autosnippet **`par`** (partial derivative).

### Disable a built-in snippet

```lua
require('latex-tools').setup({
  snippets = {
    -- Plain triggers by exact string:
    disable = { 'sr', 'cb' }, -- 'square' and 'cube' autosnippets
    -- Regex / regTrig snippets by their raw Lua pattern string:
    -- disable = { '(%d+)%*(%d+)([bBpvV])mat' }, -- dynamic matrix only
  },
})
```

### Regex trigger keys

Snippets that use `regTrig = true` are keyed by their raw Lua pattern string. Check the snippet source to find the exact pattern. Examples:

- Auto-subscript: `'([A-Za-z])(%d)'`
- Dynamic matrix: `'(%d+)%*(%d+)([bBpvV])mat'`

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

## Auto-Enlarge Brackets

When a snippet that produces `\frac`, `\int`, or `\sum` is triggered inside an existing `(...)` or `[...]` pair on the same line, the brackets are automatically enlarged with `\left` / `\right`.

**Example:**

```
(x + y/  →  \left(x + \frac{x+y}{·}\right)
```

The enlargement fires for: `/` (smart fraction), `ddt`, `dint`, `oinf`, `infi`, `\int`, `\lim`, `\sum`, `\prod`, `par`, `lim` (bare `lim` → `\lim`).

**Conditions:**
- Both the opening and matching closing bracket must already exist on the same line.
- Does nothing if the bracket is already preceded by `\left`.
- Only `(` and `[` are enlarged (`{` is not, since it is a LaTeX grouping character).

## Visual Wrappers

Five keymaps wrap a visual selection with a LaTeX annotation command. They only fire when the selection is inside a math zone.

| Default keymap | Wraps selection with |
|---------------|---------------------|
| `<leader>lu` | `\underbrace{...}_{}` |
| `<leader>lo` | `\overbrace{...}^{}` |
| `<leader>lc` | `\cancel{...}` |
| `<leader>lk` | `\cancelto{}{...}` |
| `<leader>lb` | `\underset{}{...}` |

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
