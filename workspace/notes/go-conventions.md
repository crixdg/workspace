# Go Convention Guidelines — Modern Server / System (2026)

Industry-standard Go conventions for production backend teams. Based on official Go style, Google's Go Style Guide, Uber's Go Style Guide, and community consensus as of 2026.

---

## Table of Contents

1. [Naming](#1-naming)
2. [Package Design](#2-package-design)
3. [Functions and Methods](#3-functions-and-methods)
4. [Structs and Interfaces](#4-structs-and-interfaces)
5. [Error Handling](#5-error-handling)
6. [Context Usage](#6-context-usage)
7. [Concurrency](#7-concurrency)
8. [Comments and Documentation](#8-comments-and-documentation)
9. [Code Organization within a File](#9-code-organization-within-a-file)
10. [Imports](#10-imports)
11. [Constants and Variables](#11-constants-and-variables)
12. [Testing Conventions](#12-testing-conventions)
13. [Performance Patterns](#13-performance-patterns)
14. [What Not To Do](#14-what-not-to-do)

---

## 1. Naming

### General rules

- Names are the primary form of documentation. A good name needs no comment.
- Prefer clarity over brevity at the call site, not the declaration site.
- Abbreviations are acceptable only when universally understood in Go (`ctx`, `err`, `id`, `buf`, `cfg`, `req`, `resp`, `db`, `tx`).

### Variables

```go
// Good — clear at the call site
userID := "abc123"
accountList, err := repo.List(ctx, opts)

// Bad — too short, unclear
u := "abc123"
al, e := repo.List(ctx, opts)

// Bad — too verbose, Java-style
theUserIdentifier := "abc123"
listOfUserAccounts, returnedError := repo.List(ctx, opts)
```

Loop variable names can be short (`i`, `j`, `k`, `v`) when the scope is small (< 10 lines).

### Functions and methods

- Start with a verb: `Create`, `Get`, `Update`, `Delete`, `List`, `Send`, `Parse`, `Validate`.
- Getter methods: omit `Get` — use the noun directly.

```go
// Good
func (a *Account) Status() AccountStatus { return a.status }
func (s *Service) CreateAccount(ctx context.Context, ...) {}

// Bad
func (a *Account) GetStatus() AccountStatus { return a.status }
```

- Boolean functions/methods: prefix with `Is`, `Has`, `Can`, `Should`.

```go
func (a *Account) IsActive() bool    { return a.status == StatusActive }
func (a *Account) HasVerifiedEmail() bool { return a.emailVerifiedAt != nil }
```

### Types

- Use `PascalCase` for exported types, `camelCase` for unexported.
- Suffix interfaces with `-er` when the interface describes a single behavior: `Reader`, `Writer`, `Sender`, `Publisher`, `Storer`.
- For richer interfaces, name them by role: `AccountRepository`, `EmailService`, `TokenValidator`.
- Do not suffix concrete types with `Impl` or `Struct` — the type name is the thing.

```go
// Good
type AccountRepository interface { ... }
type PostgresAccountRepository struct { ... }  // or just AccountRepository in its own package

// Bad
type IAccountRepository interface { ... }
type AccountRepositoryImpl struct { ... }
```

### Constants

```go
// Group related constants with iota or typed string constants
type AccountStatus string

const (
    AccountStatusActive    AccountStatus = "active"
    AccountStatusSuspended AccountStatus = "suspended"
    AccountStatusDeleted   AccountStatus = "deleted"
)

// Untyped const — only for truly universal values
const MaxRetries = 3
```

Never use bare `int` iota for domain concepts that will be serialized — use typed strings.

### Error variables

- Prefix unexported errors with `err`: `errInvalidEmail`.
- Prefix exported sentinel errors with `Err`: `ErrNotFound`, `ErrEmailTaken`.

```go
var (
    ErrAccountNotFound   = errors.New("account not found")
    ErrEmailAlreadyTaken = errors.New("email already taken")
)

var errInvalidToken = errors.New("invalid token")  // package-internal
```

### Acronyms

Treat acronyms as a single word — all caps or all lower, never mixed.

```go
// Good
userID     string
parseURL   func()
httpClient *http.Client
getAPIKey  func()
grpcServer *grpc.Server

// Bad
userId     string
parseUrl   func()
httpClient *http.Client  // ✓ already good, "http" is all-lower unexported
getApiKey  func()
grpcServer *grpc.Server  // ✓ already good
```

---

## 2. Package Design

### One package, one purpose

A package should be describable in one sentence without the word "and".

```
// Good
package validator   // validates user input
package mailer      // sends email
package postgres    // implements repository interfaces against PostgreSQL

// Bad
package utils       // too vague — split by purpose
package helpers     // same problem
package common      // usually a dumping ground
```

### Package names

- Always singular: `account`, not `accounts`.
- Never stutter: if the package is `account`, the type is `Account`, not `AccountAccount`.
- Short, lowercase, one word. No underscores, no camelCase.

```go
// Good
import "github.com/org/svc/internal/account"
account.Account{}       // no stutter — readable

// Bad
import "github.com/org/svc/internal/accountPackage"
accountPackage.Account{}
```

### Export policy

- Export only what external packages need. Default to unexported.
- Exported names are a public API — changing them is a breaking change.
- An unexported type can implement an exported interface.

```go
type accountService struct { ... }  // unexported concrete type

func NewAccountService(repo Repository) *accountService {
    return &accountService{repo: repo}
}
// Callers get *accountService — they use it via the AccountService interface if needed.
```

---

## 3. Functions and Methods

### Argument order

```
context → required args (most important first) → optional/config last
```

```go
func CreateAccount(ctx context.Context, email string, opts CreateOptions) (Account, error)
```

### Return values

- Return `(value, error)` — always last.
- Named return values: use only when they significantly clarify the code (e.g., multiple returns of the same type). Never use naked returns in functions longer than ~5 lines.

```go
// Good — named returns clarify what's what
func bounds(s []int) (min, max int) {
    ...
    return
}

// Bad — naked return in a long function is confusing
func processAccount(ctx context.Context, id string) (acc Account, err error) {
    // 40 lines...
    return  // which values? reader must scroll up
}
```

### Function length

- Target < 40 lines per function.
- If a function needs a comment to explain what each section does, split it into sub-functions.
- A function should do one thing at one level of abstraction.

### Receivers

- Use pointer receivers when the method mutates state or when the struct is large.
- Use value receivers for small, immutable types (value objects).
- Be consistent within a type — don't mix pointer and value receivers.

```go
// value receiver — Email is immutable
func (e Email) String() string { return e.value }

// pointer receiver — Account is mutable
func (a *Account) Suspend() error {
    if a.status == AccountStatusSuspended {
        return ErrAlreadySuspended
    }
    a.status = AccountStatusSuspended
    return nil
}
```

### Functional options pattern (for complex constructors)

```go
type ServerOption func(*Server)

func WithTimeout(d time.Duration) ServerOption {
    return func(s *Server) { s.timeout = d }
}

func WithLogger(l *slog.Logger) ServerOption {
    return func(s *Server) { s.logger = l }
}

func NewServer(addr string, opts ...ServerOption) *Server {
    s := &Server{
        addr:    addr,
        timeout: 30 * time.Second,
        logger:  slog.Default(),
    }
    for _, opt := range opts {
        opt(s)
    }
    return s
}
```

Use functional options when a constructor has more than ~3 optional parameters.

---

## 4. Structs and Interfaces

### Struct field ordering

1. Embedded types first.
2. Required/identity fields (ID, primary key).
3. Core domain fields.
4. Timestamps last (`CreatedAt`, `UpdatedAt`, `DeletedAt`).
5. For performance: group fields by type size to minimize padding (64-bit, 32-bit, smaller).

```go
type Account struct {
    ID     AccountID
    Email  string
    Name   string
    Status AccountStatus

    CreatedAt time.Time
    UpdatedAt time.Time
    DeletedAt *time.Time
}
```

### Interface size

- Prefer small, focused interfaces. One or two methods is ideal.
- Large interfaces are hard to mock, hard to satisfy, and usually indicate leaky abstraction.

```go
// Good — focused
type AccountReader interface {
    GetByID(ctx context.Context, id AccountID) (Account, error)
}

type AccountWriter interface {
    Create(ctx context.Context, acc Account) error
    Update(ctx context.Context, acc Account) error
}

// Compose when needed
type AccountRepository interface {
    AccountReader
    AccountWriter
    Delete(ctx context.Context, id AccountID) error
    List(ctx context.Context, opts ListOptions) ([]Account, error)
}
```

### Interface location

Define interfaces where they are **consumed**, not where they are **implemented**.

```go
// internal/service/account.go — defines the interface it needs
type accountRepo interface {
    GetByID(ctx context.Context, id domain.AccountID) (domain.Account, error)
    Create(ctx context.Context, acc domain.Account) error
}

// internal/repository/postgres/account.go — implements it (implicitly)
type AccountRepository struct { ... }
func (r *AccountRepository) GetByID(...) (domain.Account, error) { ... }
func (r *AccountRepository) Create(...) error { ... }
```

### Struct embedding

Use embedding to compose behavior, not to inherit implementation. Document why you're embedding.

```go
type CachedAccountRepo struct {
    postgres.AccountRepository          // fallback / write-through
    cache *redis.Client
}
```

Do not embed types just to promote their methods when wrapping is cleaner.

---

## 5. Error Handling

### Always handle errors

```go
// Bad — silent discard
_ = repo.Delete(ctx, id)

// Good
if err := repo.Delete(ctx, id); err != nil {
    return fmt.Errorf("delete account %s: %w", id, err)
}
```

### Wrap with context at every layer boundary

```go
// handler layer
if err := s.svc.Create(ctx, req.Email); err != nil {
    return fmt.Errorf("account service create: %w", err)
}

// service layer
if err := s.repo.Create(ctx, acc); err != nil {
    return fmt.Errorf("repo create account: %w", err)
}

// repository layer — translate DB-specific errors to domain errors
if errors.Is(err, pgx.ErrNoRows) {
    return domain.ErrAccountNotFound
}
return fmt.Errorf("db query: %w", err)
```

### Check errors with errors.Is / errors.As — never string matching

```go
// Good
if errors.Is(err, domain.ErrAccountNotFound) { ... }

var pgErr *pgconn.PgError
if errors.As(err, &pgErr) && pgErr.Code == "23505" { ... }

// Bad
if err.Error() == "account not found" { ... }
if strings.Contains(err.Error(), "duplicate key") { ... }
```

### Do not log and return

```go
// Bad — error logged twice (here and by caller)
if err != nil {
    slog.Error("failed to create", "err", err)
    return fmt.Errorf("create: %w", err)
}

// Good — return and let the top-level handler log once
if err != nil {
    return fmt.Errorf("create account: %w", err)
}
```

### Panic policy

- Only panic for programmer errors: nil config at startup, invalid invariants that indicate a bug.
- Never panic in request-handling code — use errors.
- `Recoverer` middleware catches panics in HTTP handlers — but relying on it is wrong.

---

## 6. Context Usage

### Rules

- `context.Context` is always the **first parameter**, named `ctx`.
- Never store a context in a struct field — pass it explicitly.
- Never pass `context.Background()` deep in business logic — only at entry points.
- Use `context.WithTimeout` / `context.WithDeadline` at I/O boundaries (DB, HTTP, RPC).

```go
// Good — ctx flows through every layer
func (h *AccountHandler) Create(w http.ResponseWriter, r *http.Request) {
    acc, err := h.svc.Create(r.Context(), req.Email)
    ...
}

func (s *AccountService) Create(ctx context.Context, email string) (Account, error) {
    return s.repo.Create(ctx, acc)
}
```

### Context values — use sparingly

Use `context.WithValue` only for request-scoped metadata that crosses API boundaries: trace IDs, authenticated user, request ID. Never for optional function arguments.

```go
// Good — request metadata
type ctxKey string
const ctxKeyUser ctxKey = "user"

func UserFromContext(ctx context.Context) (User, bool) {
    u, ok := ctx.Value(ctxKeyUser).(User)
    return u, ok
}

// Bad — passing config through context
ctx = context.WithValue(ctx, "timeout", 30*time.Second)
```

Always use an unexported key type to avoid collisions.

---

## 7. Concurrency

### Goroutine lifecycle

Every goroutine must have a clear owner responsible for waiting for it to finish.

```go
// Good — errgroup owns goroutine lifetime
g, ctx := errgroup.WithContext(ctx)
g.Go(func() error {
    return worker.Run(ctx)
})
return g.Wait()

// Bad — fire and forget with no cleanup
go func() {
    worker.Run(ctx)  // who waits for this? what if it panics?
}()
```

### Channel conventions

```go
// Unbuffered — synchronization (sender waits for receiver)
done := make(chan struct{})

// Buffered — decouple producer/consumer, known capacity
jobs := make(chan Job, 100)

// Signal channel — always chan struct{}, never chan bool
quit := make(chan struct{})
close(quit)  // broadcast to all receivers

// Directional channels in function signatures — always
func produce(ch chan<- Job)  {}
func consume(ch <-chan Job)  {}
```

### Mutex conventions

```go
type SafeCounter struct {
    mu    sync.Mutex  // unexported, named mu, placed directly above the field it guards
    count int
}

func (c *SafeCounter) Inc() {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.count++
}
```

- `sync.RWMutex`: use only when reads significantly outnumber writes and the critical section is non-trivial.
- Lock/unlock in the same function — never pass a locked mutex across function boundaries.
- Prefer `sync/atomic` for simple counters and flags over a mutex.

### Race conditions

- Always run tests with `-race`: `go test -race ./...`
- CI must include `-race` — a test suite without it is incomplete.

### select idioms

```go
// Drain a channel on shutdown
for {
    select {
    case job := <-jobs:
        process(job)
    case <-ctx.Done():
        return ctx.Err()
    }
}

// Non-blocking send
select {
case ch <- value:
default:
    // channel full — drop or log
}
```

---

## 8. Comments and Documentation

### When to comment

Write a comment only when the **why** is non-obvious. The code already shows the what.

```go
// Good — explains a non-obvious constraint
// bcrypt has a max input length of 72 bytes; truncate silently above that.
password = password[:min(len(password), 72)]

// Bad — restates the code
// increment the counter
count++

// Bad — describes what, not why
// get account by ID
acc, err := repo.GetByID(ctx, id)
```

### Doc comments

Exported types, functions, methods, and package-level variables **must** have doc comments. Start with the name.

```go
// AccountService handles account lifecycle operations.
type AccountService struct { ... }

// Create registers a new account with the given email address.
// Returns ErrEmailAlreadyTaken if the email is already in use.
func (s *AccountService) Create(ctx context.Context, email string) (Account, error) { ... }
```

### Package doc

Every package needs a one-line package comment.

```go
// Package mailer provides email sending functionality via SMTP.
package mailer
```

### TODO / FIXME format

```go
// TODO(username): remove after migration to v2 API is complete
// FIXME(username): this is O(n²) — refactor when volume exceeds 10k
```

Always include a username so it's clear who owns the follow-up.

---

## 9. Code Organization within a File

### Recommended file order

```
1. Package declaration + doc comment
2. Imports (grouped — see §10)
3. Constants
4. Package-level variables (minimize these)
5. Types (interfaces first, then structs)
6. Constructor functions (NewXxx)
7. Methods on the type (grouped: exported first, then unexported)
8. Package-level functions (exported first, then unexported)
```

### One primary type per file

```
account.go         → Account type + its methods
account_service.go → AccountService type + its methods
account_handler.go → AccountHandler type + its methods
```

Large types may span multiple files using the same package. Use suffixes:

- `_test.go` — tests
- `_integration_test.go` — integration tests
- `_bench_test.go` — benchmarks

---

## 10. Imports

Always group imports into three blocks, separated by blank lines:

```go
import (
    // 1. Standard library
    "context"
    "errors"
    "fmt"
    "net/http"
    "time"

    // 2. External dependencies
    "github.com/go-chi/chi/v5"
    "github.com/jackc/pgx/v5"
    "go.opentelemetry.io/otel"

    // 3. Internal packages
    "github.com/org/my-service/internal/domain"
    "github.com/org/my-service/internal/service"
    "github.com/org/my-service/pkg/apierr"
)
```

- `goimports` enforces this automatically — run it on save.
- Never use dot imports (`. "pkg"`) except in test files for DSLs (`. "github.com/onsi/gomega"`).
- Never use blank imports (`_ "pkg"`) outside `main.go` or `tools.go` — they hide side effects.
- Alias only to avoid collision, not for brevity:

```go
// Good — collision avoidance
chimiddleware "github.com/go-chi/chi/v5/middleware"

// Bad — brevity alias (obscures origin)
svc "github.com/org/my-service/internal/service"
```

---

## 11. Constants and Variables

### Prefer constants over variables

If a value never changes, it must be a constant. Variables mutate — constants communicate intent.

### Package-level variable rules

```go
// Good — immutable, initialized once
var defaultTimeout = 30 * time.Second

// Bad — mutable global state
var currentUser User  // race condition waiting to happen

// Bad — using var for something that could be a const
var maxRetries = 3    // should be: const maxRetries = 3
```

- Avoid `init()` functions — they execute in an unpredictable order and make testing harder.
- Global mutable state (besides `sync.Once` for lazy init) is a code smell in a server application.

### Zero value

Design types so the zero value is useful and safe.

```go
// Good — zero value of Buffer is an empty, usable buffer
var b bytes.Buffer
b.Write([]byte("hello"))

// Good — zero value of sync.Mutex is an unlocked mutex
var mu sync.Mutex
mu.Lock()
```

If the zero value of your struct is unusable, enforce initialization via a constructor and keep the struct fields unexported.

---

## 12. Testing Conventions

### Test naming

```go
// Format: Test<Unit>_<Scenario>[_<Expected>]
func TestAccountService_Create_EmailAlreadyTaken(t *testing.T) {}
func TestAccountService_Create_Success(t *testing.T) {}
func TestAccountRepository_GetByID_NotFound(t *testing.T) {}
```

### Table-driven tests

Use for multiple inputs to the same function:

```go
func TestValidateEmail(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        wantErr bool
    }{
        {"valid",          "user@example.com", false},
        {"missing at",     "userexample.com",  true},
        {"empty",          "",                 true},
        {"unicode domain", "user@münchen.de",  false},
    }

    for _, tc := range tests {
        t.Run(tc.name, func(t *testing.T) {
            _, err := NewEmail(tc.input)
            if (err != nil) != tc.wantErr {
                t.Errorf("NewEmail(%q) error = %v, wantErr %v", tc.input, err, tc.wantErr)
            }
        })
    }
}
```

### Assertions

Use `testify` — `require` for fatal failures, `assert` for non-fatal:

```go
require.NoError(t, err)           // stops test on failure
assert.Equal(t, expected, actual) // continues test on failure
assert.ErrorIs(t, err, domain.ErrNotFound)
```

### Subtests and parallel

```go
func TestSomething(t *testing.T) {
    t.Parallel()  // run this test in parallel with others

    t.Run("case A", func(t *testing.T) {
        t.Parallel()  // run subtests in parallel too
        ...
    })
}
```

### Test helpers

```go
func mustCreateAccount(t *testing.T, repo domain.AccountRepository, email string) domain.Account {
    t.Helper()  // marks this as a helper — error lines point to the caller
    acc := domain.Account{ID: "test", Email: email, Status: domain.AccountStatusActive}
    require.NoError(t, repo.Create(context.Background(), acc))
    return acc
}
```

Always call `t.Helper()` in test helper functions.

### Golden files

For complex output (JSON responses, rendered templates), use golden files:

```go
// testdata/golden/create_account_response.json
func TestHandler_CreateAccount(t *testing.T) {
    ...
    golden.Assert(t, got, "create_account_response.json")
    // update with: go test -update
}
```

---

## 13. Performance Patterns

### Prefer pre-allocation

```go
// Good — pre-allocate when size is known
results := make([]Account, 0, len(ids))

// Bad — repeated allocation via append
var results []Account
for _, id := range ids {
    results = append(results, fetch(id))
}
```

### Avoid allocations in hot paths

```go
// Use sync.Pool for short-lived, frequently allocated objects
var bufPool = sync.Pool{
    New: func() any { return new(bytes.Buffer) },
}

func encode(v any) []byte {
    buf := bufPool.Get().(*bytes.Buffer)
    defer func() {
        buf.Reset()
        bufPool.Put(buf)
    }()
    json.NewEncoder(buf).Encode(v)
    return buf.Bytes()
}
```

### String building

```go
// Good — strings.Builder for multiple concatenations
var sb strings.Builder
for _, part := range parts {
    sb.WriteString(part)
}
result := sb.String()

// Bad — O(n²) allocations
result := ""
for _, part := range parts {
    result += part
}
```

### Avoid unnecessary interface boxing

```go
// Good — concrete type in hot path
func processAccounts(accounts []Account) {}

// Slower — each element boxes to interface{}
func processItems(items []any) {}
```

### Benchmark before optimizing

```go
func BenchmarkAccountValidation(b *testing.B) {
    acc := Account{Email: "test@example.com"}
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        _ = acc.Validate()
    }
}
```

Run: `go test -bench=. -benchmem ./...`

---

## 14. What Not To Do

### Anti-patterns to avoid

```go
// ✗ Using interface{} / any where a concrete type works
func process(v any) {}     // loses type safety, forces type assertions

// ✗ Returning interfaces from constructors
func NewService() ServiceInterface { ... }  // return concrete *Service instead

// ✗ Panic in library/business code
func GetUser(id string) User {
    u, err := db.Get(id)
    if err != nil {
        panic(err)  // crash the server for one bad request
    }
    return u
}

// ✗ Ignoring errors from defer
defer resp.Body.Close()  // error silently discarded
// Better:
defer func() {
    if err := resp.Body.Close(); err != nil {
        slog.Warn("close body", "err", err)
    }
}()

// ✗ Goroutine leak — no way to stop the goroutine
go func() {
    for {
        process(queue.Next())
    }
}()

// ✗ Context stored in struct
type Service struct {
    ctx context.Context  // wrong — context has a lifetime, struct may outlive it
}

// ✗ Mutable global state
var db *sql.DB  // even if initialized once, it's a hidden dependency

// ✗ Time-based tests without injection
func TestExpiry(t *testing.T) {
    time.Sleep(2 * time.Second)  // slow, fragile
    assert.True(t, token.IsExpired())
}
// Better: inject a clock interface

// ✗ init() with side effects
func init() {
    db = connectDB()  // untestable, order-dependent
}

// ✗ Constructors that can silently fail
func NewConfig() Config {
    return Config{Secret: os.Getenv("SECRET")}  // empty string on missing var — no error
}

// ✗ Exporting types from internal packages
// internal/account/account.go exporting types that cmd/tools/ imports directly
// Use pkg/ for shared types

// ✗ Magic numbers inline
if retries > 3 { ... }         // Bad
const maxRetries = 3
if retries > maxRetries { ... } // Good

// ✗ String type for everything
func Create(userID string, roleID string, groupID string) {}  // easy to swap args
// Better: use distinct types
type UserID string
type RoleID string
func Create(userID UserID, roleID RoleID, groupID GroupID) {}
```

### Code smells to flag in review

| Smell                                  | Why it's a problem                                |
| -------------------------------------- | ------------------------------------------------- |
| `utils` / `helpers` / `common` package | Signals unclear responsibility — split by domain  |
| Function with > 5 parameters           | Consider a config struct or functional options    |
| Error wrapped more than 4 levels deep  | Layers are too granular; merge or flatten         |
| `time.Sleep` in non-test code          | Almost always wrong — use channels or tickers     |
| `os.Exit` outside `main`               | Prevents deferred cleanup, untestable             |
| Returning `(bool, error)`              | The bool is usually redundant — encode in error   |
| `log.Fatal` outside `main`             | Same problem as `os.Exit`                         |
| `http.DefaultClient` in production     | No timeout — one slow endpoint hangs your service |
| `ioutil.*` functions                   | Deprecated since Go 1.16 — use `io.*` and `os.*`  |
| `interface{}` in a new API             | Use generics (Go 1.18+) or a concrete type        |

---

## Quick reference card

```
Naming          PascalCase exports, camelCase unexported, acronyms all-caps
Packages        singular, lowercase, one word, no utils/helpers
Errors          wrap with %w, check with errors.Is/As, never log-and-return
Context         first param ctx, never store in struct, use WithTimeout at I/O
Concurrency     every goroutine has an owner, use errgroup, always -race in tests
Comments        explain WHY, not WHAT; exported symbols must have doc comments
Imports         3 groups: stdlib / external / internal
Tests           TestUnit_Scenario_Expected, table-driven, t.Helper(), t.Parallel()
Performance     pre-allocate slices, strings.Builder, benchmark before optimizing
Anti-patterns   no global state, no panic in handlers, no interface{} where avoidable
```
