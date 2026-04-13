# Speed typing for competitive programming

Conventions and Vim moves that shave seconds off every edit.

## Naming

Stick to **one style** so you do not pause mid-contest.

### Input / globals (often uppercase in templates)

| Pattern          | Meaning                                                |
| ---------------- | ------------------------------------------------------ |
| `N`, `M`         | Sizes (vertices, edges, length, …)                     |
| `K`, `Q`         | Extra parameter, query count                           |
| `W`              | Weight budget, width, or “ways”                      |
| `L`, `R`         | Bounds, interval ends                                  |
| `X`, `Y`, `Z`    | Coordinates or scalars                                 |
| `S`, `T`         | Strings (`CH` / `C` if you need one char)            |
| `P`, `P3`, `P4`  | Pair / triple / quad as a tuple                      |
| `pr`, `p0`       | Prime (keep separate if `P` is already a point/pair) |
| `A`, `B`, `C`, … | Arrays, matrices, adjacency, multisets               |

### Output

| Name  | Use                          |
| ----- | ---------------------------- |
| `res` | Helper return, partial work  |
| `ans` | Value you print / submit     |

### Locals (lowercase)

| Name                | Use                                   |
| ------------------- | ------------------------------------- |
| `i`, `j`, `k`       | Loop indices                          |
| `l`, `r`            | Interval / two-pointer                |
| `e`                 | Element in a range-for                |
| `v`                 | Generic scalar                        |
| `cnt`               | Count                                 |
| `sm`                | Sum                                   |
| `w`                 | Weight                                |
| `mn`, `mx`          | Running min / max                     |
| `ok`                | Feasibility / guard flag              |
| `cur`, `prv`, `nxt` | Walk state (tree, graph, list, …)     |

## Vim

### Enter insert

| Key | Inserts at |
| --- | ---------- |
| `i` | Before cursor |
| `I` | Start of line |
| `a` | After cursor |
| `A` | End of line |
| `o` / `O` | New line below / above |
| `ea` | After end of current word |

### Move

| Keys | Goes to |
| ---- | ------- |
| `w` / `b` / `e` | Next / prev word / end of word |
| `W` / `B` / `E` | Same for WORD (space-separated) |
| `0` / `^` / `$` / `g_` | Line start / first non-blank / end / last non-blank |
| `gg` / `G` | First / last buffer line |
| `{` / `}` | Prev / next blank-line block |
| `%` | Matching `()`, `[]`, `{}` |
| `H` / `M` / `L` | Top / middle / bottom of **window** |

### Text objects

**Pattern:** `{verb}{scope}{target}` — cursor inside the span; Vim finds the edges.

**Verbs**

| Key | Effect |
| --- | ------ |
| `c` | Delete span, **Insert** (replace) |
| `d` | **Delete** |
| `y` | **Yank** |
| `v` | **Visual** (then `y`, `d`, `>`, comments, …) |

**Scope**

| Key | Meaning |
| --- | ------- |
| `i` | **Inside** — contents only for pairs / quotes |
| `a` | **Around** — includes delimiters / quotes / word padding |

**Targets**

| Keys | Span |
| ---- | ---- |
| `(`, `[`, `{`, `"`, `'` | Block / string (pairing is symmetric for `(` / `)`) |
| `w`, `W` | Word / WORD |

**Examples:** `ci{` change inside braces · `da"` delete around a quoted string · `yiw` yank inner word.

**Change without an object:** `cc` whole line · `cw` / `cb` word forward / back · `c$` / `c^` to line end / first non-blank (all end in Insert).

### Marks

- `m{a-z}` — set mark  
- `` `{a-z} `` — jump to exact position · `'{a-z}` — jump to line  

Use for “template footer”, `main`, or a scratch line you jump to often.

### Search, indent, repeat

- `.` — repeat last change  
- `*` / `#` — next / prev word under cursor  
- `>>` / `<<` — indent / dedent line  
- `=` + motion — re-indent (`=ap` paragraph)  
- `Ctrl-v` — block visual (grids, aligned columns)  
- `:s/old/new/g` — current line · `:%s/old/new/g` — whole file  

### Macros

- `qa` … `q` — record into register `a`  
- `@a` — play once · `10@a` — ten times · `@@` — repeat last `@`  

`qaq` clears register `a`. Any `a`–`z` works.

### Case (normal mode)

- `~` — toggle case on character (respects count)  
- `guiw` / `gUiw` — lower / upper **inner word**  

---

**VS Code / Cursor:** same idea — match bracket jump, expand selection, multi-cursor on matches, snippets for `read` / graph boilerplate so names stay stable with less typing.
