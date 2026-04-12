# Speed Typing for Competitive Programming

## Variable Naming Conventions

- **Using consistent naming style for INPUT variables** (UPPERCASE)
  - `N`, `M` for number of elements, number of operations, etc.
  - `K`, `Q` for number of constraints, number of queries, etc.
  - `W` for weight constraints, number of ways, etc.
  - `L`, `R` for left, right boundaries, limits
  - `X`, `Y`, `Z` for coordinates, points, etc.
  - `S`, `CH` for strings, characters, etc.
  - `P`, `P3`, `P4` for pair, triple, quadruple, etc.
  - `P` for prime number
  - `A`, `B`, `C`, `D`, `E` for arrays, vectors, matrices, etc.
- **Using consistent naming style for OUTPUT variables** (lowercase)
  - `res` for method result, intermediate result
  - `ans` for final problem answer
- **Using consistent naming style for LOGIC variables** (lowercase)
  - `i`, `j`, `k` for loop indices
  - `l`, `r` for left, right boundaries, limits
  - `e` for loop element, iterating over array `A`
  - `v` for value
  - `cnt` for count
  - `sm` for sum
  - `w` for weight
  - `mn`, `mx` for minimum, maximum
  - `ok` for boolean variable indicating whether a condition is satisfied
  - `cur`, `prv`, `nxt` for current, previous value in tree/graph traversal

## Vim Typing Techniques

- **Stop "walking", start "jumping"**
  - 

## Core Vim mechanics (biggest ROI)

- **Stay in Normal mode by default.** Enter Insert only for actual text entry; exit with `Esc` or `Ctrl-[` so you can move and edit structurally.
- **Master “word” vs “WORD”:** `w` / `b` / `e` vs `W` / `B` / `E` — useful for jumping identifiers and long tokens.
- **Vertical movement:** `}` / `{` (paragraphs), `]]` / `[[` (often useful in C++ with braces), `%` on `()[]{}`, `gd` / `gD` if you use LSP or tags.
- **Text objects:** `ci"`, `ci'`, `ci)`, `ci{`, `cit` (markup), `cip` — change “inside” without hunting endpoints. `diw`, `ciw`, `caw` for tokens.
- **Repeatability:** `.` repeats the last change; combine with `;` and `,` after `f` / `F` / `t` / `T` for fast in-line jumps.
- **Macros:** `qa` … `q` then `@a` and `@@` for repetitive I/O or struct fills (avoid over-investing mid-contest).
- **Marks:** `ma` … `` `a `` or `'a` for jumping between regions (e.g. input parsing vs main logic).
- **Search as navigation:** `*` / `#` on a symbol; `n` / `N`. Consider `incsearch` / `hlsearch` if you like them. `Ctrl-o` / `Ctrl-i` for jump history if you rely on jumps.

## Competitive programming–specific patterns

- **Snippets for boilerplate:** `main`, `for` loops, `using ll = long long;`, `#include` blocks, common structs — keep snippets **short** so maintenance stays light.
- **Brace and semicolon habits:** `A;`, `o{`, etc.; `gg=G` after big pastes if you use `=` for indent.
- **Fast commenting:** one consistent approach (e.g. `gcc` with a plugin, or visual block + `I` for line prefixes).
- **Multi-cursor:** optional; if you use it, pick one workflow. Otherwise prefer `%s` or macros so you do not hesitate under time pressure.

## Fewer mistakes under time pressure

- **Don’t look at the keyboard** for `Esc`, numbers, or movement — remap if `Esc` is slow (e.g. `jj` / `jk` in Insert, or `Ctrl-[`).
- **Stable formatting:** same tabs/spaces as your template so muscle memory matches what you submit.
- **One template command:** open today’s file with includes and `int main()` (or language equivalent) so you never type headers from scratch in a rush.

## Plugins (only if they do not slow thinking)

- **LSP / completion:** helpful for long names; keep completion **small and predictable** so popups do not steal focus in contests.
- **Fuzzy finders** help large repos more than single-file CP; for many people, one buffer per problem and simple `:e` is mentally faster.

## Practice that transfers

- **Vim:** drill motions and text objects, not only prose typing tests (e.g. structured “change inside this string” reps).
- **CP:** cold-type your template until automatic; timed “fill this stub” reps (BFS template, segtree skeleton, etc.).
- **After contests:** notice repeated awkward edits and add **one** mapping or snippet per week — avoid churning remaps.

## Mental model

The editor is **a program that edits programs**: motions and text objects are navigation “algorithms”; snippets are your “library.” The goal is **boring, stable muscle memory** so under pressure you spend cycles on the problem, not on hunting a brace.

## Optional follow-up

If you narrow your stack (Neovim vs Vim, C++ vs Python, LSP/snippets on or off), you can order the items above into a **short priority list** (e.g. first ten habits) for your setup.
