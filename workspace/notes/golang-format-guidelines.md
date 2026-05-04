# Go Format Guidelines

> Canonical formatting rules for Go code. Covers tooling, import layout, declaration style, and whitespace.
> Project/architectural rules → `golang-guidelines.md`
> Language patterns → `golang-expertise.md`

---

## Table of Contents

1. [Tooling](#1-tooling)
2. [Import Groups](#2-import-groups)
3. [Package & File Layout](#3-package--file-layout)
4. [Declarations](#4-declarations)
5. [Function Signatures](#5-function-signatures)
6. [Structs](#6-structs)
7. [Whitespace & Blank Lines](#7-whitespace--blank-lines)
8. [Line Length](#8-line-length)
9. [Comments](#9-comments)
10. [Error & Control Flow Style](#10-error--control-flow-style)
11. [Receiver Style](#11-receiver-style)
12. [golangci-lint Reference](#12-golangci-lint-reference)
    - [Config File Structure](#config-file-structure)
    - [Category 1 — Core Correctness](#category-1--core-correctness-always-enable)
    - [Category 2 — Resource Lifecycle](#category-2--resource-lifecycle)
    - [Category 3 — Logic & Runtime Safety](#category-3--logic--runtime-safety)
    - [Category 4 — API & Data Boundary](#category-4--api--data-boundary)
    - [Category 5 — Code Quality & Maintainability](#category-5--code-quality--maintainability)
    - [Category 6 — Error Design Consistency](#category-6--error-design-consistency)
    - [Category 7 — Context Correctness](#category-7--context-correctness)
    - [Category 8 — Architecture & Policy](#category-8--architecture--policy)
    - [Category 9 — Efficiency & Idiomatic Usage](#category-9--efficiency--idiomatic-usage)
    - [Category 10 — Dead Code & Cleanliness](#category-10--dead-code--cleanliness)
    - [Category 11 — Style & Formatting](#category-11--style--formatting)
    - [Category 12 — Security (gosec)](#category-12--security-gosec)
    - [Category 13 — Edge-Case & Unicode Safety](#category-13--edge-case--unicode-safety)
    - [Category 14 — Testing Quality](#category-14--testing-quality)
    - [Category 15 — Ecosystem-Specific](#category-15--ecosystem-specific)
    - [Category 16 — Structural & Design Constraints](#category-16--structural--design-constraints)
    - [Full .golangci.yml Example](#full-golangciyml-example)
    - [GitHub Actions](#github-actions)
    - [Adoption Strategy](#adoption-strategy)
    - [Priority Reference](#priority-reference)

---

## 1. Tooling

Run these before every commit — they are non-negotiable:

| Tool | Purpose | Command |
|---|---|---|
| `gofumpt` | Strict superset of `gofmt` — owns all whitespace, syntax, and blank-line formatting | `gofumpt -l -w -extra .` |
| `gci` | Import group ordering with custom local-prefix rule | `gci write --custom-order -s standard -s default -s "prefix($(MODULE))" -s blank --no-lex-order --skip-generated --skip-vendor .` |
| `golines` | Wraps lines exceeding 120 characters | `golines -w -m 120 .` |
| `golangci-lint` | Meta-linter (50+ checks, includes `gofumpt` check) | `golangci-lint run` |

**Run in this order:**

```bash
# 1. Auto-add/remove imports + gofmt baseline
goimports -w .

# 2. Import group ordering (custom groups with local prefix)
gci write --custom-order \
  -s standard \
  -s default \
  -s "prefix($(MODULE))" \
  -s blank \
  --no-lex-order \
  --skip-generated \
  --skip-vendor \
  .

# 3. Line wrapping
golines -w -m 120 .

# 4. Strict formatting (superset of gofmt — applies on top without unwrapping lines)
gofumpt -l -w -extra .
```

**Why `gofumpt` last:** `gofumpt` does not unwrap lines — it only adjusts whitespace, blank lines, and indentation. Running it after `golines` is safe as long as the pipeline is idempotent. Verify by running the full pipeline twice: if the second pass produces no diff, the order is stable.

**Why `goimports` before `gci`:** `goimports` auto-adds/removes unused imports; `gci` then re-sorts the groups. `goimports`'s own sorting is discarded by `gci`, but the import resolution is preserved.

```bash
# Install
go install golang.org/x/tools/cmd/goimports@latest
go install github.com/daixiang0/gci@latest
go install github.com/segmentio/golines@latest
go install mvdan.cc/gofumpt@latest
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Verify in CI (no writes, exit 1 on diff)
goimports -l . | grep . && exit 1 || true
gci diff --custom-order -s standard -s default -s "prefix($(MODULE))" -s blank --no-lex-order --skip-generated --skip-vendor . | grep . && exit 1 || true
golines -m 120 --dry-run . | grep . && exit 1 || true
gofumpt -l -extra . | grep . && exit 1 || true
```

---

## 2. Import Groups

`goimports` manages ordering. Follow this **three-group** convention:

```go
import (
    // Group 1 — stdlib
    "context"
    "errors"
    "fmt"
    "net/http"

    // Group 2 — third-party
    "github.com/jackc/pgx/v5"
    "go.uber.org/zap"

    // Group 3 — internal (your module)
    "github.com/yourorg/yourservice/internal/domain"
    "github.com/yourorg/yourservice/internal/usecase"
)
```

**Rules:**
- One blank line between each group; no blank lines within a group
- `gci` enforces all four groups automatically via the `prefix(MODULE)` flag — do not sort imports by hand
- No aliased imports unless there is a genuine name collision
- Dot imports (`import . "pkg"`) only in test files and only when idiomatic (e.g., `gomega`)
- Blank imports (`import _ "pkg"`) go in `main.go` or a dedicated `init.go`, not scattered in logic files

---

## 3. Package & File Layout

**File naming:**
```
user.go            — domain entity or primary type
user_handler.go    — HTTP handler for user resource
user_repository.go — DB implementation for user
user_test.go       — tests (same package for white-box)
user_internal_test.go  — (avoid: split only when truly needed)
```

**Within a file, top-to-bottom order:**
1. `package` declaration
2. `import` block
3. Constants (`const`)
4. Package-level variables (`var`) — keep minimal; prefer constructor injection
5. Type declarations (`type`)
6. Constructor functions (`New...`)
7. Methods — public before private, grouped by receiver
8. Package-private helpers

**Rules:**
- One primary type per file; helpers that only serve that type live in the same file
- `doc.go` only when the package has complex exported surface that needs a standalone overview
- No `utils.go`, `helpers.go`, `common.go` — name by what the code does, not that it's miscellaneous

---

## 4. Declarations

**Constants:**
```go
// GOOD — grouped, typed when used with type switches
const (
    StatusActive   = "active"
    StatusInactive = "inactive"
)

// GOOD — iota for sequential integer enums
type Direction int

const (
    North Direction = iota
    South
    East
    West
)

// BAD — mixed typed and untyped in one block (confusing)
const (
    MaxRetries = 3
    Timeout    time.Duration = 5 * time.Second // separate blocks
)
```

**Variables:**
```go
// Short declaration inside functions — always preferred
id := "abc"

// Package-level — only for truly global state (errors, singletons)
var ErrNotFound = errors.New("not found")

// BAD — zero-value var when := works
var name string
name = "alice"

// GOOD
name := "alice"
```

**Type assertions:**
```go
// Always use the two-value form outside type switches
v, ok := x.(string)
if !ok {
    // handle
}

// Single-value form panics on mismatch — only acceptable when you control the value
```

---

## 5. Function Signatures

**Parameter order:** context → required inputs → optional modifiers → out-params (rare).

```go
// GOOD
func CreateUser(ctx context.Context, email, name string) (*User, error)

// BAD — context buried
func CreateUser(email string, ctx context.Context, name string) (*User, error)
```

**Return values:**
```go
// GOOD — named returns only to document what each value means
func divide(a, b float64) (result float64, err error)

// BAD — named returns used as a shortcut to naked-return
func getUser(id string) (user *User, err error) {
    // ... lots of code
    return // naked return — invisible, hard to follow
}

// GOOD — explicit returns
func getUser(id string) (*User, error) {
    // ...
    return user, nil
}
```

**Variadic options (functional options pattern):**
```go
type ServerOption func(*serverConfig)

func WithTimeout(d time.Duration) ServerOption {
    return func(c *serverConfig) { c.timeout = d }
}

func NewServer(addr string, opts ...ServerOption) *Server
```

**Rules:**
- Avoid more than 4–5 parameters; beyond that introduce a request struct
- Never use `bool` as a parameter — create two functions or use a typed option
- Error is always the last return value

```go
// BAD
func Process(data []byte, verbose bool) error

// GOOD
func Process(data []byte) error
func ProcessVerbose(data []byte) error
// or
type ProcessOptions struct { Verbose bool }
func Process(data []byte, opts ProcessOptions) error
```

---

## 6. Structs

**Field alignment — group by type to minimize padding:**
```go
// BAD — wastes 7 bytes to padding
type Record struct {
    active bool      // 1 byte
    // 7 bytes padding
    count  int64     // 8 bytes
    flag   bool      // 1 byte
    // 7 bytes padding
}

// GOOD — pack bools together; largest types first
type Record struct {
    count  int64   // 8 bytes
    active bool    // 1 byte
    flag   bool    // 1 byte
    // 6 bytes padding (one block)
}
```

**Struct tags:**
```go
type User struct {
    ID        string    `json:"id"                db:"id"`
    Email     string    `json:"email"             db:"email"`
    CreatedAt time.Time `json:"created_at"        db:"created_at"`
    // omitempty only for truly optional fields
    Nickname  string    `json:"nickname,omitempty" db:"nickname"`
}
```

**Rules:**
- Align struct tags in a column (gofmt does not enforce this, but it aids readability for structs > 3 fields)
- Embed only interfaces, not concrete structs — embedding concrete types leaks methods and creates surprise coupling
- Zero-value should be usable where possible; document when it isn't

```go
// GOOD — zero value is a valid, unlocked mutex
type Cache struct {
    mu    sync.Mutex
    items map[string]any
}
```

---

## 7. Whitespace & Blank Lines

`gofmt` owns indentation and spacing within expressions. These rules cover blank lines, which `gofmt` does **not** enforce:

```go
// One blank line between top-level declarations
func Foo() {}

func Bar() {}

// One blank line between logical sections inside a function
func ProcessOrder(ctx context.Context, id string) error {
    order, err := s.repo.GetOrder(ctx, id)
    if err != nil {
        return err
    }

    if err := s.inventory.Reserve(ctx, order.Items); err != nil {
        return fmt.Errorf("reserve inventory: %w", err)
    }

    return s.repo.UpdateStatus(ctx, id, StatusProcessed)
}

// No blank line between a comment and the thing it describes
// GetOrder retrieves an order by ID.
func GetOrder(ctx context.Context, id string) (*Order, error)

// No trailing blank lines inside a function or block
func Bad() {
    doSomething()

}  // <-- trailing blank line, remove it
```

**Rules:**
- Max one consecutive blank line anywhere
- No blank line immediately after `{` or immediately before `}`
- Blank line before a `return` is fine when it ends a logical section; unnecessary after a single short statement

---

## 8. Line Length

Go has no enforced line length. Practical guideline: **120 characters** (hard limit for linters; target ≤100 for diffs).

**Wrapping long function calls:**
```go
// GOOD — each argument on its own line when the call doesn't fit
result, err := somepackage.LongFunctionName(
    ctx,
    firstArgument,
    secondArgument,
    thirdArgument,
)

// GOOD — fluent builder on separate lines
req := httptest.NewRequest(http.MethodPost, "/api/v1/users", body).
    WithContext(ctx)
```

**Wrapping long conditions:**
```go
// GOOD — operator at the start of the continuation line
if user.IsActive() &&
    user.HasPermission(PermCreate) &&
    !user.IsLocked() {
    // ...
}
```

**Wrapping struct literals:**
```go
// GOOD — trailing comma on last element
cfg := Config{
    Host:    "localhost",
    Port:    5432,
    MaxConn: 25,
}
```

---

## 9. Comments

**Package comment:**
```go
// Package handler implements HTTP handlers for the user resource.
package handler
```

**Exported symbol comment — starts with the symbol name:**
```go
// UserHandler handles HTTP requests for user management.
type UserHandler struct { ... }

// Create handles POST /api/v1/users.
func (h *UserHandler) Create(w http.ResponseWriter, r *http.Request) { ... }
```

**Rules:**
- Every exported type, function, constant, and variable must have a doc comment
- Comment starts with the symbol name (golint enforces this)
- Use full sentences ending with a period
- No `// nolint` without a reason in the same comment: `//nolint:errcheck // response write error is ignorable here`
- TODO format: `// TODO(username): description` — searchable, attributable

**What NOT to comment:**
```go
// BAD — restates what the code says
// increment i by 1
i++

// BAD — explains the what, not the why
// call Close on the file
defer f.Close()

// GOOD — explains the non-obvious why
// Drain before closing to allow connection reuse by the transport.
defer func() {
    io.Copy(io.Discard, resp.Body)
    resp.Body.Close()
}()
```

---

## 10. Error & Control Flow Style

**Early return over nesting:**
```go
// BAD — pyramid of doom
func process(r *http.Request) error {
    if r != nil {
        body, err := io.ReadAll(r.Body)
        if err == nil {
            if len(body) > 0 {
                // real work
            }
        }
    }
    return nil
}

// GOOD — guard clauses
func process(r *http.Request) error {
    if r == nil {
        return errors.New("nil request")
    }
    body, err := io.ReadAll(r.Body)
    if err != nil {
        return fmt.Errorf("read body: %w", err)
    }
    if len(body) == 0 {
        return nil
    }
    // real work
    return nil
}
```

**if-err pattern:**
```go
// GOOD — declare err in the if initializer when it's only used in the branch
if err := db.Ping(ctx); err != nil {
    return fmt.Errorf("db ping: %w", err)
}

// Use plain assignment when err is reused
user, err := repo.GetUser(ctx, id)
if err != nil {
    return nil, err
}
order, err := repo.GetOrder(ctx, user.OrderID) // reuse err
```

**Switch over if-else chains:**
```go
// BAD
if status == "active" {
} else if status == "inactive" {
} else if status == "pending" {
}

// GOOD
switch status {
case "active":
case "inactive":
case "pending":
default:
}
```

---

## 11. Receiver Style

**Pointer vs value receiver — pick one per type:**

```go
// Use pointer receiver when:
// - method mutates the receiver
// - receiver is large (copying is expensive)
// - receiver contains a sync type (Mutex, WaitGroup)
func (u *User) Activate() { u.Active = true }

// Use value receiver when:
// - receiver is a small, immutable value type
// - method is a pure transformer
func (p Point) Scale(f float64) Point { return Point{p.X * f, p.Y * f} }
```

**Rules:**
- All methods on a type must use the same receiver style (all pointer or all value) — mixed styles confuse the interface satisfaction rules
- Receiver name: 1–2 letter abbreviation of the type, consistent across all methods
  ```go
  func (u *UserHandler) ...   // not (h *UserHandler) or (self *UserHandler)
  func (r *UserRepository) ...
  ```
- Never use `this` or `self` as a receiver name

---

## 12. golangci-lint Reference

golangci-lint is a **meta-linter aggregator** — it runs 100+ linters concurrently under one config and one fast binary. The de facto standard for Go CI pipelines.

**Why Go projects need it:**
- The Go compiler catches type errors, not bugs like unchecked errors, nil dereferences, or resource leaks
- Many production failures are detectable statically before they ship
- Unifies ~100 linters under one config, one run, one cache

**Signal quality spectrum:**
- **High signal, low noise** — `staticcheck`, `govet`, `errcheck`, `bidichk`, `durationcheck`
- **Medium signal, tune carefully** — `revive`, `gocritic`, `cyclop`, `wrapcheck`
- **Noisy, team-consensus required** — `varnamelen`, `whitespace`, `wsl_v5`, `funlen`
- **Ecosystem-specific** — `testifylint`, `sloglint`, `ginkgolinter` (only if you use that lib)

---

### Config File Structure

```yaml
run:
  timeout: 5m
  go: "1.22"
  modules-download-mode: readonly

linters:
  disable-all: true   # opt-in only — prevents surprise linters on upgrades
  enable:
    - govet
    - staticcheck
    # ... add explicitly

linters-settings:
  errcheck:
    check-type-assertions: true
    check-blank: true

issues:
  exclude-rules:
    - path: _test\.go
      linters: [errcheck, gosec, wrapcheck, exhaustruct]
    - path: \.pb\.go$
      linters: [all]
  max-issues-per-linter: 0
  max-same-issues: 0
  new: false   # flip to true to lint only changed lines in PRs
```

---

### Category 1 — Core Correctness (Always Enable)

These five linters form a **layered defense** — each covers a distinct bug class, so their overlap is intentional.

| Layer | Linter | Bug class |
|-------|--------|-----------|
| Language safety | `govet` | Format mismatches, struct literal errors, loop capture |
| Deep static analysis | `staticcheck` | Nil dereference, concurrency, deprecated API, dead code |
| Error handling | `errcheck` | Unchecked error return values |
| Error chain | `errorlint` | Broken `errors.Is/As` chains (`==` comparison, `%v` wrapping) |
| Error design | `err113` | String comparisons, scattered sentinel errors |

#### `govet`

Built by the Go team. Catches language-level mistakes that compile but produce wrong behavior.

```go
fmt.Printf("%d", "hello")   // wrong format specifier — compiles, wrong output

for i := 0; i < 10; i++ {
    go func() { fmt.Println(i) }()  // loop variable capture
}
```

Partially overlaps with `staticcheck` but is the official baseline and runs faster. Always keep both.

#### `staticcheck`

Highest-value single linter. Deep inter-procedural analysis catches nil dereferences, concurrency bugs, deprecated API usage, and incorrect stdlib patterns.

```go
var x *int
if x == nil {
    fmt.Println(*x)  // panic — staticcheck catches this
}

time.Tick(time.Second)  // memory leak: leaks the underlying ticker; use time.NewTicker
```

Broad overlap with many linters but no single linter is exhaustive — run the others alongside it.

#### `errcheck`

Flags every ignored error return — Go's #1 source of silent production failures.

```go
f, _ := os.Open("file.txt")   // error discarded
json.Unmarshal(data, &v)       // error discarded
```

A DB write silently fails, the function returns success, data is lost. `staticcheck` catches some ignored errors; `errcheck` is stricter and purpose-built.

```yaml
linters-settings:
  errcheck:
    check-type-assertions: true  # flags: val := x.(string) with no ok
    check-blank: true            # flags: err, _ := doThing()
```

#### `errorlint`

Ensures correct Go 1.13+ error wrapping semantics. Direct equality comparison breaks when errors are wrapped.

```go
// BAD — fails when err is wrapped: fmt.Errorf("context: %w", io.EOF)
if err == io.EOF { ... }
if err == ErrNotFound { ... }

// GOOD
if errors.Is(err, io.EOF) { ... }

// BAD — loses wrapped error; caller can't use errors.Is/As
fmt.Errorf("failed: %v", err)

// GOOD
fmt.Errorf("failed: %w", err)
```

#### `err113`

Enforces how errors are **defined**, not just how they're compared. Prevents fragile string comparisons and scattered ad-hoc error values.

```go
// BAD — breaks if message changes; not comparable with errors.Is
if err.Error() == "not found" { ... }
return errors.New("something went wrong")  // inline, scattered

// GOOD — package-level sentinel
var ErrNotFound = errors.New("not found")
if errors.Is(err, ErrNotFound) { ... }
```

Most valuable in large codebases and public APIs where error contracts matter.

---

### Category 2 — Resource Lifecycle

These linters catch bugs that **compile fine but cause leaks and silent failures under load**. All four are orthogonal to core correctness linters — no overlap.

| Resource | Required action | Consequence if skipped |
|----------|----------------|------------------------|
| HTTP response body | `resp.Body.Close()` | TCP connection leak, pool exhaustion |
| SQL rows | `rows.Close()` | DB connection leak, `too many connections` |
| SQL iteration | `rows.Err()` check | Silent partial data on network errors |
| Tracing span | `span.End()` | Memory leak, broken distributed traces |

#### `bodyclose`

Every `http.Response.Body` must be closed, even on error paths. Forgetting leaks one TCP connection per request.

```go
// BAD — connection pool exhausts under load
resp, err := http.Get(url)
if err != nil { return err }
// body never closed

// GOOD
resp, err := http.Get(url)
if err != nil { return err }
defer resp.Body.Close()
```

#### `sqlclosecheck`

Unclosed `*sql.Rows` and `*sql.Stmt` hold live connections until GC — which is unpredictable.

```go
rows, err := db.Query("SELECT * FROM users")
if err != nil { return err }
defer rows.Close()  // required
```

#### `rowserrcheck`

`rows.Next()` returns `false` on both normal completion *and* mid-stream errors. Without checking `rows.Err()` you silently return a truncated result set.

```go
for rows.Next() {
    rows.Scan(&u)
    results = append(results, u)
}
if err := rows.Err(); err != nil {  // required — errcheck does NOT catch this
    return nil, err
}
```

#### `spancheck`

Spans must be ended; errors should be recorded on the span.

```go
// BAD — span leaks memory, trace is broken
ctx, span := tracer.Start(ctx, "operation")
if err != nil { return err }  // span.End() never called

// GOOD
ctx, span := tracer.Start(ctx, "operation")
defer span.End()
if err != nil {
    span.RecordError(err)
    span.SetStatus(codes.Error, err.Error())
    return err
}
```

Enable for: HTTP+DB backends → `bodyclose + sqlclosecheck + rowserrcheck`. Add `spancheck` if using OpenTelemetry/Jaeger.

---

### Category 3 — Logic & Runtime Safety

Bugs that compile, pass tests, and fail unpredictably in production due to Go's subtle semantics.

#### `copyloopvar`

Classic Go concurrency bug: closures capture the loop variable by reference.

```go
// BAD — all goroutines likely print the final value of v
for _, v := range []int{1, 2, 3} {
    go func() { fmt.Println(v) }()
}

// GOOD — shadow v to create a new binding per iteration
for _, v := range []int{1, 2, 3} {
    v := v
    go func() { fmt.Println(v) }()
}
```

> Go 1.22+ changed loop semantics — each iteration gets its own variable. Still worth keeping for codebases with older `go.mod` language versions.

#### `forcetypeassert`

Unguarded `x.(T)` panics at runtime on wrong type.

```go
// BAD — panics if cache holds anything other than string
name := cache["username"].(string)

// GOOD
name, ok := cache["username"].(string)
if !ok { return fmt.Errorf("unexpected type for username") }
```

#### `exhaustive`

Ensures every `switch` over an `iota` enum handles all cases. Adding a new enum value silently leaves existing switches incomplete.

```go
type Status int
const (
    Pending  Status = iota
    Approved
    Rejected  // added later — exhaustive flags all switches missing this case
)

// BAD — returns "" silently for Rejected
func label(s Status) string {
    switch s {
    case Pending:  return "waiting"
    case Approved: return "done"
    }
    return ""
}
```

#### `nilnil`

Prevents returning `(nil, nil)` — forces callers to check both return values.

```go
// BAD — caller can't distinguish "not found" from success
func findUser(id int) (*User, error) { return nil, nil }
```

#### `nilerr`

Catches returning `nil` when `err != nil` — a logic inversion bug.

```go
if err != nil {
    return nil  // BAD: should be return err
}
```

---

### Category 4 — API & Data Boundary

Correctness at system boundaries — bugs that don't crash but produce wrong behavior or protocol violations.

#### `errchkjson`

`json.Marshal` and `json.Encoder.Encode` can fail. The `Encode` case is dangerous: `http.ResponseWriter` may have already sent a 200 status and partial bytes before the error, so the client receives corrupted JSON with no indication of failure.

```go
// BAD — silent failure; may send empty or partial JSON
data, _ := json.Marshal(v)

// BAD — client may receive truncated response with no error signal
json.NewEncoder(w).Encode(v)

// GOOD
if err := json.NewEncoder(w).Encode(v); err != nil {
    return fmt.Errorf("encoding response: %w", err)
}
```

#### `canonicalheader`

Go's `http.Header` stores keys in canonical form internally. Accessing headers with non-canonical keys creates duplicate entries that coexist with the canonical version, breaking middleware and proxies.

```go
// BAD — creates a separate non-canonical key; canonical "Content-Type" may coexist
req.Header["content-type"] = []string{"application/json"}

// GOOD — Set/Get/Add/Del canonicalize automatically
req.Header.Set("Content-Type", "application/json")
req.Header.Set("X-Request-Id", "abc123")
```

---

### Category 5 — Code Quality & Maintainability

These linters prevent code from becoming hard to test and evolve. Value compounds over time.

#### `revive`

Configurable replacement for `golint`. Enforces Go conventions: exported types need doc comments, error strings must not be capitalized, avoid `if-else` where a direct `return` suffices.

```go
// flagged: exported with no doc comment
func HandleRequest(w http.ResponseWriter, r *http.Request) {}

// flagged: capitalized error string
return fmt.Errorf("User not found")  // should be "user not found"
```

```yaml
linters-settings:
  revive:
    rules:
      - name: exported
      - name: error-strings
      - name: indent-error-flow
      - name: unused-parameter
      - name: redefines-builtin-id
```

#### `gocritic`

Large rule set covering performance hints, code simplifications, and subtle bugs. Enable selectively.

```go
s := fmt.Sprintf("%s", str)  // unnecessary Sprintf — simplify to: s := str
if x == true { ... }         // redundant comparison — simplify to: if x { ... }
func process(data BigStruct)  // hugeParam: large struct copied by value — use pointer
```

```yaml
linters-settings:
  gocritic:
    enabled-checks:
      - appendAssign   # append result not assigned back
      - sloppyLen      # len(x) > 0 should be len(x) != 0
      - hugeParam      # large struct passed by value
      - rangeValCopy   # large loop copy
```

#### `cyclop`

Cyclomatic complexity limit — counts independent code paths (each `if`, `for`, `case`, `&&`, `||` adds one). High complexity = many untestable paths.

```yaml
linters-settings:
  cyclop:
    max-complexity: 10    # per-function limit; 15 acceptable for business logic
    package-average: 5.0  # catches files where every function is just under the limit
    skip-tests: true
```

#### `funlen`

Flags functions exceeding a line/statement threshold. Complements `cyclop` — a short function with 10 branches fails `cyclop`; a 200-line function with one branch fails `funlen`.

```yaml
linters-settings:
  funlen:
    lines: 80
    statements: 60
```

Use `//nolint:funlen` for legitimate orchestration functions rather than splitting logic artificially.

#### `goconst`

Finds string literals repeated more than a configurable number of times that should be named constants. The risk is silent divergence — changing a string value in one place and missing the others.

```go
// BAD — "application/json" repeated across handlers
req.Header.Set("Content-Type", "application/json")
// ... elsewhere:
w.Header().Set("Content-Type", "application/json")

// GOOD
const contentTypeJSON = "application/json"
```

```yaml
linters-settings:
  goconst:
    min-len: 3          # minimum string length to flag
    min-occurrences: 3  # flag when repeated this many times
```

#### `mnd`

Detects magic numbers — bare numeric literals that have no self-documenting meaning at the call site.

```go
// BAD — what does 86400 mean?
time.Sleep(86400 * time.Second)
if retries > 3 { ... }

// GOOD
const secondsPerDay = 86400
const maxRetries = 3
```

```yaml
linters-settings:
  mnd:
    checks: [argument, case, condition, operation, return, assign]
    ignored-numbers: [0, 1, 2]   # common idioms; expand as needed
    ignored-functions:
      - make
      - len
      - cap
```

#### `dupl`

Detects structurally identical code blocks. The risk is not duplication itself — it's that bug fixes applied to one copy are missed in the others, causing silent divergence.

```yaml
linters-settings:
  dupl:
    threshold: 150  # tokens; lower = stricter
```

Exclude generated files in `issues.exclude-rules`.

---

### Category 6 — Error Design Consistency

The complete error-handling linter stack, each covering a distinct concern:

| Linter | Responsibility |
|--------|---------------|
| `errcheck` | Don't ignore returned errors |
| `errorlint` | Use `errors.Is/As` and `%w` correctly |
| `err113` | Define sentinel errors at package level |
| `wrapcheck` | Add context when propagating across boundaries |
| `errname` | Name error variables consistently |

#### `wrapcheck`

Errors propagated without wrapping lose call-stack context. The difference in debuggability:

```
# Without wrapping:
connection refused

# With wrapping:
fetch user profile (id=42): query DB: connection refused
```

```go
// BAD — caller sees raw os/net error
func fetchUser(id int) (*User, error) {
    return db.QueryUser(id)
}

// GOOD — each layer adds context
func fetchUser(id int) (*User, error) {
    u, err := db.QueryUser(id)
    if err != nil {
        return nil, fmt.Errorf("fetch user (id=%d): %w", id, err)
    }
    return u, nil
}
```

Sentinel errors should **not** be wrapped when you want callers to match them exactly with `errors.Is`.

```yaml
linters-settings:
  wrapcheck:
    ignorePackageGlobs:
      - "github.com/yourorg/yourrepo/*"  # internal packages don't need wrapping
    ignoreSigRegexps:
      - \.New\(   # ignore errors.New() calls
```

#### `errname`

Enforces Go convention: exported error variables use `ErrXxx`, unexported use `errXxx`, error types end in `Error`.

```go
// BAD
var NotFound = errors.New("not found")
var errnotfound = errors.New("not found")
type notFoundProblem struct{}

// GOOD
var ErrNotFound = errors.New("not found")
var errTimeout = errors.New("timeout")
type NotFoundError struct{ ID int }
```

---

### Category 7 — Context Correctness

`context.Context` misuse doesn't break compilation but causes **leaks, stuck requests, and silent failures under load**.

| Rule | Linter | Real-world failure |
|------|--------|-------------------|
| Always pass context down | `contextcheck` | HTTP cancelled, DB query keeps running |
| Don't misuse lifecycle in loops | `fatcontext` | Background job leaks thousands of timers |
| Don't store context in structs | `containedctx` | Service reuses cancelled context → random failures |

#### `contextcheck`

Ensures context is propagated from callers to callees. Using `context.Background()` inside a function that received a context discards the caller's cancellation and deadline.

```go
// BAD — DB query ignores HTTP request cancellation
func GetUser(ctx context.Context, id int) (*User, error) {
    return db.QueryRow("SELECT * FROM users WHERE id = ?", id)
    // should be: db.QueryRowContext(ctx, ...)
}

// BAD — throws away incoming context entirely
func process(ctx context.Context) {
    ctx = context.Background()  // discards cancellation signal
    doWork(ctx)
}
```

Use `context.WithoutCancel(ctx)` (Go 1.21+) to detach from cancellation while keeping values.

#### `fatcontext`

`defer cancel()` inside a loop body defers until the *function* exits, not the *iteration* end — holding all timers simultaneously.

```go
// BAD — N iterations = N live timers until function returns
for _, item := range items {
    ctx, cancel := context.WithTimeout(parentCtx, time.Second)
    defer cancel()  // runs at function exit, not iteration end
    process(ctx, item)
}

// GOOD
for _, item := range items {
    ctx, cancel := context.WithTimeout(parentCtx, time.Second)
    process(ctx, item)
    cancel()  // called immediately
}
```

#### `containedctx`

Enforces Go's official guideline: **do not store `context.Context` inside a struct**. The struct may outlive the original request, meaning later calls silently use a cancelled or expired context.

```go
// BAD — which context? from when? still valid?
type UserService struct {
    ctx context.Context
    db  *sql.DB
}

// GOOD — context is request-scoped, passed per-operation
type UserService struct{ db *sql.DB }

func (s *UserService) GetUser(ctx context.Context, id int) (*User, error) {
    return s.db.QueryRowContext(ctx, ...).Scan(...)
}
```

---

### Category 8 — Architecture & Policy

These linters encode **team decisions** into the lint pipeline. They enforce structural constraints rather than correctness.

#### `depguard`

Restricts import paths, enforcing layer boundaries at lint time.

```yaml
linters-settings:
  depguard:
    rules:
      no-direct-db-in-handlers:
        files: ["**/handler/**/*.go"]
        deny:
          - pkg: "database/sql"
            desc: "handlers must use the service layer"
      no-ioutil:
        deny:
          - pkg: "io/ioutil"
            desc: "deprecated since Go 1.16, use io and os"
```

#### `forbidigo`

Bans specific function calls or patterns. Start with high-impact, unambiguous rules.

```yaml
linters-settings:
  forbidigo:
    forbid:
      - pattern: "^fmt\\.Print(ln|f)?$"
        msg: "use structured logger"
      - pattern: "^log\\.Fatal(f|ln)?$"
        msg: "log.Fatal calls os.Exit, preventing deferred cleanup; return errors"
      - pattern: "^time\\.Sleep$"
        msg: "blocks goroutine; use context-aware waits in handlers"
      - pattern: "^rand\\.Intn$"
        msg: "math/rand is not cryptographically secure; use crypto/rand for tokens"
```

`log.Fatal` bypasses all deferred cleanup (DB close, span end, mutex unlock) before exiting. `time.Sleep` in a hot path under load causes goroutine pile-up. Both are easy to accidentally introduce and hard to find in production logs.

---

### Category 9 — Efficiency & Idiomatic Usage

Low noise, good cleanup. Prevent technical debt from silently accumulating.

#### `wastedassign`

Catches assignments whose value is never read — stronger than `ineffassign`. Most dangerous on `err` variables.

```go
err := stepOne()
err = stepTwo()   // BAD: stepOne's error silently dropped before being checked
if err != nil { return err }
```

#### `unconvert`

Removes type conversions that do nothing.

```go
s := string("hello")     // already a string
i := int64(int64(x))     // double conversion
```

#### `prealloc`

Suggests pre-allocating slices when the length is known.

```go
// flagged
var results []string
for _, item := range items { results = append(results, process(item)) }

// suggested
results := make([]string, 0, len(items))
```

#### `unparam`

Detects function parameters always called with the same constant value, or never used inside the function.

```yaml
linters-settings:
  unparam:
    check-exported: false  # don't flag exported functions (interface implementations)
```

#### `usestdlibvars`

Flags string literals that should be stdlib constants.

```go
req.Method = "get"          // should be http.MethodGet
resp.StatusCode == 200      // should be http.StatusOK
os.OpenFile(path, 2, 0644)  // 2 = what? should be os.O_RDWR
```

#### `exptostd`

Flags `golang.org/x/exp` imports that have stdlib equivalents. Common promotions in Go 1.21+:

| `x/exp` package | Stdlib since |
|----------------|-------------|
| `golang.org/x/exp/slices` | `slices` (1.21) |
| `golang.org/x/exp/maps` | `maps` (1.21) |
| `golang.org/x/exp/slog` | `log/slog` (1.21) |

Only enable if your `go.mod` `go` directive is at the required version.

---

#### `unqueryvet`

Flags `SELECT *` SQL queries. Over-fetching columns wastes bandwidth and breaks when columns are added, reordered, or removed — `rows.Scan` calls dependent on column order will corrupt data or panic.

---

### Category 10 — Dead Code & Cleanliness

Low noise, high signal. Enable `unused` and `ineffassign` on every project from day one.

#### `unused`

Detects unexported identifiers (functions, types, constants) never referenced anywhere. Goes beyond the compiler, which only errors on unused local variables.

```go
func helper() {}           // compiler allows this — unused catches it
type internalState struct{} // same
const maxRetries = 3       // same
```

Exported identifiers (`func Export()`, `type Public struct{}`) are never flagged — they may be used by external packages.

#### `ineffassign`

Catches assignments whose value is never read before being overwritten or going out of scope.

```go
x := 10
x = compute()   // the 10 is never observed
```

Run both `ineffassign` and `wastedassign` — `ineffassign` handles obvious cases fast; `wastedassign` tracks across more complex control flow.

#### `dogsled`

Flags too many blank identifiers in a single assignment. Multiple `_` often signals a poorly designed API or a caller ignoring results they should handle.

```go
_, _, _, err := parseRecord(line)  // flagged with max-blank-identifiers: 2
```

```yaml
linters-settings:
  dogsled:
    max-blank-identifiers: 2
```

#### `godox`

Flags `TODO`, `FIXME`, `HACK` comments. Prevents tech-debt markers from living forever.

```yaml
linters-settings:
  godox:
    keywords: [FIXME, HACK, OPTIMIZE]
```

#### `dupword`

Duplicate adjacent words in comments (`// This function function handles`). Zero noise, easy fix.

---

### Category 11 — Style & Formatting

Enforce conventions, not correctness. Value scales with team size. **Introduce with team consensus only.**

| Linter | Noise | When worth enabling |
|--------|-------|---------------------|
| `misspell` | Very low | Always — catches typos in comments/strings |
| `godot` | Low | Teams with `go doc` standards |
| `tagalign` | Low | Any codebase with struct tags (auto-fixable) |
| `tagliatelle` | Low–Medium | APIs with strict JSON/YAML tag conventions |
| `lll` | Low | Teams with an explicit line length policy |
| `varnamelen` | Medium–High | Only with careful ignore list tuning |
| `decorder` | Low | Large packages with many top-level declarations |
| `funcorder` | Low–Medium | Teams wanting exported functions surfaced first |
| `whitespace` / `wsl_v5` | **Very high** | Large teams only, full consensus, run against full codebase first |

#### `tagalign`

Auto-fixable (`golangci-lint run --fix`). Aligns struct tag spacing consistently.

#### `tagliatelle`

Enforces tag naming conventions (snake_case, camelCase, etc.).

```yaml
linters-settings:
  tagliatelle:
    case:
      rules:
        json: snake
        yaml: snake
        db: snake
```

#### `varnamelen`

Must be tuned before enabling — Go idioms actively encourage short names in specific contexts.

```yaml
linters-settings:
  varnamelen:
    min-name-length: 3
    ignore-names: [err, ok, id, db, wg, mu, i, j, k, v, w, r]
    ignore-type-assert-ok: true
    ignore-chan-recv-ok: true
    ignore-map-index-ok: true
```

**Never enable `wsl_v5` or `whitespace` without running against the full existing codebase first** — violations on an existing project will number in the hundreds and bury real findings.

---

### Category 12 — Security (gosec)

`gosec` is categorically different from every other linter. It targets **exploitability** — bugs that don't crash, pass all tests, and only manifest under attack. No other linter in the ecosystem covers this domain.

**Command injection (G204)**
```go
// BAD — user controls shell execution
exec.Command("sh", "-c", userInput)

// GOOD — argument list bypasses shell; -- prevents flag injection
exec.Command("/usr/bin/git", "clone", "--", repoURL)
```

**SQL injection (G202)**
```go
// BAD — input: ' OR '1'='1 → returns all rows
db.Query("SELECT * FROM users WHERE name = '" + name + "'")

// GOOD — parameterized
db.QueryContext(ctx, "SELECT * FROM users WHERE name = ?", name)
```

**Hardcoded credentials (G101)**
```go
const apiKey = "sk-prod-abc123xyz"  // appears in binary, version control, crash dumps
```

**Weak cryptography (G501 / G401)**
```go
md5.Sum(data)   // MD5 and SHA1 are broken for security purposes
sha1.Sum(data)  // use sha256.Sum256 or better
```

**Path traversal (G304)**
```go
// BAD — ../../etc/passwd
os.Open("/data/uploads/" + filename)

// GOOD — validate after cleaning
clean := filepath.Clean(filepath.Join("/data/uploads", filename))
if !strings.HasPrefix(clean, "/data/uploads/") {
    return errors.New("invalid path")
}
os.Open(clean)
```

**Insecure randomness (G404)**
```go
rand.Int()  // math/rand is deterministic; use crypto/rand for tokens
```

**Insecure TLS (G402)**
```go
// BAD — vulnerable to MITM
TLSClientConfig: &tls.Config{InsecureSkipVerify: true}
```

**Handling false positives** — use targeted suppression with justification:

```go
// #nosec G304 -- path constructed from validated config, not user input
f, err := os.Open(filepath.Join(configDir, "settings.json"))

// #nosec G401 -- MD5 used for cache key deduplication, not security
key := fmt.Sprintf("%x", md5.Sum([]byte(content)))
```

```yaml
linters-settings:
  gosec:
    severity: medium
    confidence: medium
    excludes:
      - G104   # suppress if errcheck already covers ignored errors
```

Enable for any service handling external input. There is no fallback — no other linter covers this layer.

---

### Category 13 — Edge-Case & Unicode Safety

Low noise, serious consequences when triggered.

#### `bidichk`

Detects Unicode bidirectional control characters — the **Trojan Source attack** (CVE-2021-42574). These characters are invisible in most editors but change how the compiler reads the text. Near-zero false positives. **Enable unconditionally.**

#### `durationcheck`

Catches `time.Duration` unit mistakes — the most common being a bare integer treated as nanoseconds.

```go
time.Sleep(5)                              // 5 nanoseconds, not 5 seconds
time.Sleep(time.Duration(timeout))         // 1000ns if timeout=1000, not 1000ms
delay := 2 * time.Second * time.Millisecond  // ns² — meaningless unit; compiles cleanly
```

`staticcheck` catches some duration misuse; `durationcheck` catches the multiplication case and others `staticcheck` misses. **Enable unconditionally.**

#### `asciicheck`

Enforces ASCII-only identifiers. Prevents homoglyph attacks — visually identical characters from non-Latin scripts.

```go
var user = "alice"  // ASCII 'u'
var usеr = "bob"   // Cyrillic 'е' (U+0435) — looks identical, different identifier
```

---

### Category 14 — Testing Quality

These linters prevent **flaky tests, misleading failure output, and structural test problems**.

#### `thelper`

When a test helper calls `t.Fatal` without `t.Helper()`, every failure reports the helper's line — not the test that called it.

```go
// BAD — failure reported inside check(), not at the call site
func check(t *testing.T, err error) {
    if err != nil { t.Fatal(err) }
}

// GOOD
func check(t *testing.T, err error) {
    t.Helper()
    if err != nil { t.Fatal(err) }
}
```

Very low noise. **Enable unconditionally for any project with test helpers.**

#### `tparallel`

Catches `t.Parallel()` misuse — most commonly the loop variable capture in parallel subtests.

```go
// BAD — all subtests use the final loop value of tc
for _, tc := range testCases {
    t.Run(tc.name, func(t *testing.T) {
        t.Parallel()
        run(tc.input)  // tc is the loop variable — race
    })
}

// GOOD
for _, tc := range testCases {
    tc := tc
    t.Run(tc.name, func(t *testing.T) {
        t.Parallel()
        run(tc.input)
    })
}
```

#### `testifylint`

Ensures the correct testify assertion is used. Wrong assertions produce misleading failure output.

```go
// BAD — failure message: "expected: <nil>, got: <nil>"
assert.Equal(t, nil, err)
assert.Equal(t, true, ok)

// GOOD — clear failure messages
assert.NoError(t, err)
assert.True(t, ok)
```

Only enable if using `github.com/stretchr/testify`.

#### `testpackage`

Forces tests to use `package foo_test` — external test package. Tests can only access exported identifiers, simulating real consumer usage. High value for libraries/SDKs.

#### `testableexamples`

`Example*` functions without `// Output:` comments run but their output is never verified — they can silently rot.

```go
// BAD — runs, but output never checked
func ExampleSortUsers() {
    fmt.Println(users[0].Name)
}

// GOOD — verified on every test run
func ExampleSortUsers() {
    fmt.Println(users[0].Name)
    // Output: Alice
}
```

**Test file exclusion pattern:**
```yaml
issues:
  exclude-rules:
    - path: _test\.go
      linters: [errcheck, gosec, wrapcheck, exhaustruct]
```

---

### Category 15 — Ecosystem-Specific

Only enable if the matching library is in your `go.mod`. Otherwise these produce zero findings or false positives.

| Linter | Required dependency | Enforces |
|--------|-------------------|---------|
| `ginkgolinter` | `github.com/onsi/ginkgo` | Idiomatic Ginkgo structure and matcher usage |
| `zerologlint` | `github.com/rs/zerolog` | Structured zerolog API; catches unterminated event chains |
| `sloglint` | `log/slog` (stdlib Go 1.21+) | Structured slog; no string concatenation in log calls |
| `arangolint` | ArangoDB Go driver | ArangoDB-specific resource lifecycle |

**`zerologlint` key pattern:** a log event built without a terminal `Msg()`/`Send()` call is silently dropped.

```go
log.Info().Str("user", name)  // BAD — event never dispatched
log.Info().Str("user", name).Msg("login")  // GOOD
```

**`sloglint` key pattern:** odd-number key-value pairs produce malformed structured log output.

```go
slog.Info("event", "user", name, "action")  // BAD — "action" has no value
slog.Info("event", "user", name, "action", act)  // GOOD
```

```yaml
linters-settings:
  sloglint:
    no-mixed-args: true
    kv-only: true
    static-msg: true
```

---

### Category 16 — Structural & Design Constraints

Enforce architectural discipline. High friction — introduce deliberately and incrementally.

#### `gochecknoglobals`

Package-level `var` creates shared mutable state accessible from anywhere — hidden dependencies that make functions impure and tests order-dependent.

```go
// BAD — any function can read or mutate; test isolation requires global teardown
var db *sql.DB
var cache = make(map[string]*User)

// GOOD — dependencies are explicit and injectable
type Service struct {
    db    *sql.DB
    cache UserCache
}
```

Legitimate exceptions: sentinel errors (`var ErrNotFound`), `sync.Once`, compile-time interface checks (`var _ Interface = (*Type)(nil)`). Suppress those with `//nolint:gochecknoglobals`.

#### `gochecknoinits`

`init()` runs implicitly, in dependency order, with no way for callers to control or observe it. Hard to test, hidden in stack traces.

```go
// BAD — panics at import; caller has no way to handle gracefully
func init() {
    db, err = sql.Open("postgres", os.Getenv("DATABASE_URL"))
    if err != nil { log.Fatal(err) }
}

// GOOD — explicit constructor; caller controls error handling
func NewDB(dsn string) (*sql.DB, error) {
    return sql.Open("postgres", dsn)
}
```

#### `exhaustruct`

Requires all struct fields to be explicitly set. Prevents silent zero-value bugs when structs gain new required fields.

```go
// BAD — new Timeout field silently gets 0 (no timeout)
cfg := ServerConfig{Host: "localhost", Port: 8080}

// GOOD — new field forces you to consciously decide its value
cfg := ServerConfig{Host: "localhost", Port: 8080, Timeout: 30 * time.Second}
```

**High friction warning.** Enable only for critical domain types, not globally.

```yaml
linters-settings:
  exhaustruct:
    include:
      - "github.com/yourorg/yourrepo/domain\\..*"
```

#### `interfacebloat`

Flags interfaces exceeding a method count — signals interface segregation violation.

```yaml
linters-settings:
  interfacebloat:
    max: 5
```

---

### Full .golangci.yml Example

```yaml
run:
  timeout: 5m
  go: "1.22"
  modules-download-mode: readonly

linters:
  disable-all: true
  enable:
    # Category 1 — Core Correctness
    - govet
    - staticcheck
    - errcheck
    - errorlint
    - err113

    # Category 2 — Resource Lifecycle
    - bodyclose
    - sqlclosecheck
    - rowserrcheck
    - spancheck          # if using tracing

    # Category 3 — Logic & Runtime Safety
    - copyloopvar
    - forcetypeassert
    - exhaustive
    - nilnil
    - nilerr

    # Category 4 — API & Data Boundary
    - errchkjson
    - canonicalheader

    # Category 5 — Code Quality
    - revive
    - gocritic
    - cyclop
    - goconst
    - mnd

    # Category 6 — Error Design
    - wrapcheck
    - errname

    # Category 7 — Context
    - contextcheck
    - fatcontext
    - containedctx

    # Category 8 — Architecture
    - depguard
    - forbidigo

    # Category 9 — Efficiency
    - wastedassign
    - usestdlibvars
    - prealloc

    # Category 10 — Dead Code
    - unused
    - ineffassign
    - dogsled
    - dupword

    # Category 11 — Style (tune before enabling)
    - misspell
    - tagalign
    - tagliatelle

    # Category 12 — Security
    - gosec

    # Category 13 — Edge-Case Safety
    - bidichk
    - durationcheck
    - asciicheck

    # Category 14 — Testing
    - thelper
    - tparallel
    - testifylint       # if using testify
    - testpackage
    - testableexamples

linters-settings:
  errcheck:
    check-type-assertions: true
    check-blank: true

  gosec:
    severity: medium
    confidence: medium

  cyclop:
    max-complexity: 10
    package-average: 5.0
    skip-tests: true

  revive:
    rules:
      - name: exported
      - name: error-strings
      - name: indent-error-flow
      - name: unused-parameter

  wrapcheck:
    ignorePackageGlobs:
      - "github.com/yourorg/yourrepo/*"

  gocritic:
    enabled-checks: [appendAssign, sloppyLen, hugeParam, rangeValCopy]

  depguard:
    rules:
      no-ioutil:
        deny:
          - pkg: "io/ioutil"
            desc: "deprecated since Go 1.16"

  forbidigo:
    forbid:
      - pattern: "^fmt\\.Print(ln|f)?$"
        msg: "use structured logger"
      - pattern: "^log\\.Fatal(f|ln)?$"
        msg: "return errors instead of os.Exit"

  goconst:
    min-len: 3
    min-occurrences: 3
    ignore-tests: true

  mnd:
    checks: [argument, case, condition, operation, return, assign]
    ignored-numbers: [0, 1, 2]
    ignored-functions: [make, len, cap]

  dogsled:
    max-blank-identifiers: 2

  tagliatelle:
    case:
      rules:
        json: snake
        yaml: snake
        db: snake

issues:
  exclude-rules:
    - path: _test\.go
      linters: [errcheck, gosec, wrapcheck, exhaustruct]
    - path: \.pb\.go$
      linters: [all]
  max-issues-per-linter: 0
  max-same-issues: 0
  new: false
```

---

### GitHub Actions

```yaml
# .github/workflows/lint.yml
name: Lint

on:
  push:
    branches: [main]
  pull_request:

jobs:
  golangci-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-go@v5
        with:
          go-version: "1.22"
          cache: false  # golangci-lint manages its own cache

      - uses: golangci/golangci-lint-action@v6
        with:
          version: v1.59
          args: --timeout=5m
```

---

### Adoption Strategy

**Step 1 — Day one (zero noise, maximum signal)**
```yaml
enable: [govet, staticcheck, errcheck, unused, ineffassign, bidichk, durationcheck]
```

**Step 2 — Production baseline (after step 1 is clean)**
```yaml
# add:
- errorlint
- err113
- bodyclose
- sqlclosecheck
- rowserrcheck
- wrapcheck
- contextcheck
- gosec
- thelper
```

**Step 3 — Quality & architecture (after team alignment)**
```yaml
# add:
- revive
- gocritic
- cyclop
- depguard
- forbidigo
- exhaustive
- copyloopvar
```

**Step 4 — Strict (deliberate, with consensus)**
```yaml
# add (tune carefully):
- gochecknoglobals
- gochecknoinits
- exhaustruct        # domain package only
- varnamelen         # with ignore list
- tagalign
- tagliatelle
```

---

### Priority Reference

| Category | Key linters | Enable when |
|----------|-------------|-------------|
| Core correctness | `govet`, `staticcheck`, `errcheck`, `errorlint`, `err113` | Always, day one |
| Resource lifecycle | `bodyclose`, `sqlclosecheck`, `rowserrcheck` | Any HTTP or DB code |
| Logic safety | `copyloopvar`, `forcetypeassert`, `exhaustive`, `nilnil` | All production services |
| API boundary | `errchkjson`, `canonicalheader` | REST APIs, microservices |
| Code quality | `revive`, `gocritic`, `cyclop`, `goconst`, `mnd` | Growing teams |
| Error design | `wrapcheck`, `errname` | Multi-layer services, libraries |
| Context | `contextcheck`, `fatcontext`, `containedctx` | HTTP servers, concurrent code |
| Architecture | `depguard`, `forbidigo` | Layered services, monorepos |
| Security | `gosec` | Always — any service handling input |
| Edge-case safety | `bidichk`, `durationcheck`, `asciicheck` | Always (low noise) |
| Testing | `thelper`, `tparallel` | Any project with test helpers |
| Ecosystem | `testifylint`, `sloglint`, `zerologlint` | Only if lib is in go.mod |
| Structural | `gochecknoglobals`, `exhaustruct` | Large systems, strict DI |
| Style | `misspell`, `tagalign`, `tagliatelle` | Medium+ teams with consensus |
