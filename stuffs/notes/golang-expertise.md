# Golang Expertise: Complete Reference for Production Systems

> Combines coding conventions, codebase architecture, server patterns, microservice design, and infrastructure — everything needed to build and operate Go systems at scale.

---

## Table of Contents

### Language & Runtime
1. [Go Fundamentals & Idioms](#1-go-fundamentals--idioms)
2. [Type System & Interfaces](#2-type-system--interfaces)
3. [Error Handling Mastery](#3-error-handling-mastery)
4. [Context Discipline](#4-context-discipline)
5. [Concurrency Patterns](#5-concurrency-patterns)
6. [Generics](#6-generics)
7. [Memory Model & Runtime Internals](#7-memory-model--runtime-internals)
8. [Performance & Profiling](#8-performance--profiling)

### Server Patterns
9. [HTTP Server Architecture](#9-http-server-architecture)
10. [gRPC & Streaming](#10-grpc--streaming)
11. [WebSockets & SSE](#11-websockets--sse)
12. [Middleware Engineering](#12-middleware-engineering)
13. [API Design & Versioning](#13-api-design--versioning)

### Microservice Patterns
14. [Service Decomposition](#14-service-decomposition)
15. [Inter-Service Communication](#15-inter-service-communication)
16. [Event-Driven Architecture](#16-event-driven-architecture)
17. [CQRS & Event Sourcing](#17-cqrs--event-sourcing)
18. [Saga Pattern](#18-saga-pattern)
19. [Resilience Patterns](#19-resilience-patterns)
20. [Distributed Tracing & Correlation](#20-distributed-tracing--correlation)

### Data Layer
21. [Database Patterns at Scale](#21-database-patterns-at-scale)
22. [Transaction Management](#22-transaction-management)
23. [Outbox Pattern](#23-outbox-pattern)
24. [Caching Strategies](#24-caching-strategies)

### Infrastructure
25. [Container Hardening](#25-container-hardening)
26. [Kubernetes Production Setup](#26-kubernetes-production-setup)
27. [Observability Stack](#27-observability-stack)
28. [CI/CD & GitOps](#28-cicd--gitops)
29. [Security in Depth](#29-security-in-depth)
30. [Operational Runbooks](#30-operational-runbooks)

---

## 1. Go Fundamentals & Idioms

### Naming — the single most impactful practice

Names are documentation. Optimize for readability at the **call site**, not the declaration.

```go
// Accepted abbreviations (universally understood in Go)
ctx   context.Context
err   error
id    string/int
buf   []byte / bytes.Buffer
cfg   Config
req   *http.Request
resp  *http.Response
db    *pgxpool.Pool
tx    pgx.Tx
w     http.ResponseWriter
r     *http.Request
wg    sync.WaitGroup
mu    sync.Mutex
```

```go
// Acronyms: all-caps or all-lower, never mixed
userID    string    // good
userUrl   string    // bad — should be userURL
parseUrl  func()   // bad — should be parseURL
httpClient         // good — "http" is the package prefix, stays lowercase
grpcServer         // good
getApiKey  func()  // bad — should be getAPIKey
```

```go
// Functions: start with a verb
CreateUser, GetAccount, UpdateOrder, DeleteSession
ListProducts, SendEmail, ParseToken, ValidateInput
IsActive, HasPermission, CanDelete  // booleans

// Getters: omit "Get"
func (a *Account) Status() AccountStatus  // not GetStatus()
func (u *User) Email() string             // not GetEmail()
```

### Package design

```go
// One package = one clearly nameable purpose
package validator   // validates inputs
package mailer      // sends emails
package postgres    // postgres repository implementations
package jwt         // JWT encoding/decoding

// Never:
package utils       // too vague
package helpers     // same problem
package common      // a dumping ground
package shared      // if "shared" by everything, it has no identity
```

Package names: singular, lowercase, one word, no underscores.

```go
// Stutter rule: package name + type name must not repeat
// package: account
type Account struct{}          // good — account.Account
type AccountModel struct{}     // bad  — account.AccountModel (stutter + "Model" noise)

// package: auth
type Token struct{}            // good — auth.Token
type AuthToken struct{}        // bad  — auth.AuthToken (stutter)
```

### Zero values — design for them

```go
// Good: zero value is usable
var b bytes.Buffer     // ready to write
var mu sync.Mutex      // ready to lock
var wg sync.WaitGroup  // ready to Add

// Design your own types this way
type RateLimiter struct {
    mu       sync.Mutex
    requests []time.Time
    limit    int
    window   time.Duration
}

// Bad: zero value panics
type Cache struct {
    data map[string]any  // nil map panics on write
}
// Fix: initialize in constructor or use sync.Map
```

### Constants over variables

```go
// Types for domain constants — not bare ints
type OrderStatus string
const (
    OrderStatusPending   OrderStatus = "pending"
    OrderStatusPaid      OrderStatus = "paid"
    OrderStatusShipped   OrderStatus = "shipped"
    OrderStatusCancelled OrderStatus = "cancelled"
)

// iota only for bit flags or truly ordinal values that never serialize
type Permission uint
const (
    PermRead   Permission = 1 << iota // 1
    PermWrite                          // 2
    PermDelete                         // 4
    PermAdmin                          // 8
)
```

Never use `iota` for anything that touches JSON, a database, or a wire format — the int values shift when you insert a new constant.

### Functional options for complex constructors

```go
type Server struct {
    addr         string
    timeout      time.Duration
    maxConns     int
    logger       *slog.Logger
    tlsConfig    *tls.Config
}

type Option func(*Server)

func WithTimeout(d time.Duration) Option {
    return func(s *Server) { s.timeout = d }
}
func WithMaxConns(n int) Option {
    return func(s *Server) { s.maxConns = n }
}
func WithTLS(cfg *tls.Config) Option {
    return func(s *Server) { s.tlsConfig = cfg }
}

func NewServer(addr string, opts ...Option) *Server {
    s := &Server{
        addr:     addr,
        timeout:  30 * time.Second,
        maxConns: 1000,
        logger:   slog.Default(),
    }
    for _, o := range opts {
        o(s)
    }
    return s
}

// Usage — readable, self-documenting
srv := NewServer(":8080",
    WithTimeout(60*time.Second),
    WithMaxConns(5000),
    WithTLS(tlsCfg),
)
```

Use functional options when a constructor has more than ~3 optional parameters or when consumers need to customize a subset of many fields.

---

## 2. Type System & Interfaces

### Interface design — small and focused

```go
// Ideal: 1-2 methods
type Reader interface {
    Read(ctx context.Context, id string) (Entity, error)
}

type Writer interface {
    Write(ctx context.Context, e Entity) error
}

// Compose larger interfaces from smaller ones
type ReadWriter interface {
    Reader
    Writer
}
```

The Go standard library proves this: `io.Reader`, `io.Writer`, `io.Closer` — each is one method. `io.ReadWriteCloser` composes them.

### Interfaces belong at the consumer

```go
// BAD: interface defined where it's implemented
// internal/repository/postgres/account.go
type AccountRepository interface {  // ← wrong place
    GetByID(ctx context.Context, id string) (Account, error)
}
type postgresRepo struct{}
func (r *postgresRepo) GetByID(...) (Account, error) { ... }

// GOOD: interface defined where it's consumed
// internal/service/account.go
type accountRepo interface {  // unexported — only this package needs it
    GetByID(ctx context.Context, id string) (Account, error)
    Create(ctx context.Context, acc Account) error
}

type AccountService struct {
    repo accountRepo  // depends on the interface, not the concrete type
}
```

This is the Dependency Inversion Principle, Go-style. The repository package has no interface — it just exports a concrete type that happens to satisfy whatever interface any consumer defines.

### Never return interfaces from constructors

```go
// Bad — forces callers to use only the interface
func NewAccountService() AccountServiceInterface { ... }

// Good — return concrete type; callers decide if they need the interface
func NewAccountService(repo accountRepo) *AccountService { ... }
```

The exception: when the concrete type should be hidden entirely (`http.Handler`, `io.Reader`).

### Embedding vs wrapping

```go
// Embedding — promotes methods, use for behavior composition
type InstrumentedRepo struct {
    *PostgresRepo       // all methods promoted
    tracer trace.Tracer
}

// Wrapping — explicit delegation, use when you want to control the API
type CachedRepo struct {
    db    *PostgresRepo  // not embedded — you choose which methods to expose
    cache *redis.Client
}

func (r *CachedRepo) GetByID(ctx context.Context, id string) (Account, error) {
    // cache logic, then delegate to r.db.GetByID
}
```

Prefer wrapping when you're decorating behavior — it prevents accidental exposure of methods you haven't audited.

### Type aliases for domain primitives

```go
// Distinct types prevent parameter order bugs
type UserID   string
type OrderID  string
type ProductID string

func PlaceOrder(userID UserID, productID ProductID) error { ... }

// Compiler catches this:
PlaceOrder(productID, userID)  // compile error — types don't match
```

---

## 3. Error Handling Mastery

### Wrapping at every layer boundary

```go
// Each layer adds context without hiding the root cause
// repository layer
if errors.Is(err, pgx.ErrNoRows) {
    return domain.ErrNotFound  // translate DB error to domain error
}
return fmt.Errorf("db get user %s: %w", id, err)  // wrap with context

// service layer
user, err := s.repo.GetByID(ctx, id)
if err != nil {
    return fmt.Errorf("UserService.GetByID: %w", err)  // add layer context
}

// handler layer — unwrap and map
if errors.Is(err, domain.ErrNotFound) {
    respondError(w, http.StatusNotFound, "user not found")
    return
}
```

Error chain after wrapping: `"UserService.GetByID: db get user abc: sql: no rows"`

### Sentinel errors

```go
// internal/domain/errors.go
var (
    ErrNotFound      = errors.New("not found")
    ErrAlreadyExists = errors.New("already exists")
    ErrUnauthorized  = errors.New("unauthorized")
    ErrForbidden     = errors.New("forbidden")
    ErrInvalidInput  = errors.New("invalid input")
    ErrConflict      = errors.New("conflict")
)
```

Check with `errors.Is` — never string-match:

```go
if errors.Is(err, domain.ErrNotFound) { ... }    // good
if err.Error() == "not found" { ... }             // bad — breaks wrapping
if strings.Contains(err.Error(), "not found") {}  // bad — fragile
```

### Structured error types for rich context

When you need to carry data with an error:

```go
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation failed on %s: %s", e.Field, e.Message)
}

// Extract with errors.As
var ve *ValidationError
if errors.As(err, &ve) {
    slog.Warn("validation failed", "field", ve.Field, "msg", ve.Message)
}
```

### One place to log

```go
// BAD — logged twice, stack trace noise
func (s *Service) Create(ctx context.Context, email string) error {
    if err := s.repo.Create(ctx, email); err != nil {
        slog.Error("repo create failed", "err", err)  // ← logs here
        return fmt.Errorf("create: %w", err)           // ← and propagates
    }
    return nil
}

// In the handler:
if err := s.svc.Create(ctx, req.Email); err != nil {
    slog.Error("svc create failed", "err", err)  // ← logged again
    respondError(w, 500, "internal error")
}

// GOOD — return only, log once at the top
// service: just return
// handler: log once, respond
if err := s.svc.Create(ctx, req.Email); err != nil {
    slog.ErrorContext(ctx, "create user", "err", err)
    handleError(w, err)
}
```

### Panic policy

```go
// Only acceptable panics:
// 1. At startup, for unrecoverable configuration errors
cfg, err := config.Load()
if err != nil {
    // os.Exit is better than panic here — cleaner output
    slog.Error("failed to load config", "err", err)
    os.Exit(1)
}

// 2. For programmer errors (unreachable code, broken invariants)
func processStatus(s OrderStatus) {
    switch s {
    case OrderStatusPending: ...
    case OrderStatusPaid: ...
    default:
        panic(fmt.Sprintf("unhandled order status: %s", s))
    }
}

// Never panic in request-handling code
// Never panic in library code
```

---

## 4. Context Discipline

### Rules — non-negotiable

```go
// 1. First parameter, always named ctx
func (s *Service) CreateUser(ctx context.Context, email string) (User, error)

// 2. Never store context in a struct
type Service struct {
    ctx context.Context  // WRONG — context has a request lifetime, struct doesn't
}

// 3. Only create root contexts at entry points
func main() {
    ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGTERM)
    defer stop()
    app.Run(ctx)
}

func handler(w http.ResponseWriter, r *http.Request) {
    // Use r.Context() — already has request-scoped deadline/cancel
    result, err := svc.Do(r.Context(), params)
}

// 4. Add timeouts at I/O boundaries
func (r *repo) GetByID(ctx context.Context, id string) (User, error) {
    ctx, cancel := context.WithTimeout(ctx, 3*time.Second)
    defer cancel()
    return r.db.QueryRow(ctx, query, id).Scan(...)
}
```

### Context values — what belongs there

```go
// GOOD: request-scoped metadata
type contextKey string
const (
    ctxKeyRequestID contextKey = "request_id"
    ctxKeyUserID    contextKey = "user_id"
    ctxKeyTraceID   contextKey = "trace_id"
)

func WithRequestID(ctx context.Context, id string) context.Context {
    return context.WithValue(ctx, ctxKeyRequestID, id)
}

func RequestIDFromContext(ctx context.Context) (string, bool) {
    id, ok := ctx.Value(ctxKeyRequestID).(string)
    return id, ok
}

// BAD: business data in context — makes dependencies invisible
ctx = context.WithValue(ctx, "user", user)     // use function params instead
ctx = context.WithValue(ctx, "db", db)         // inject via constructor
ctx = context.WithValue(ctx, "timeout", 30)    // pass explicitly
```

Always use an unexported type (not `string`) as the context key to prevent collision between packages.

### Context cancellation propagation

```go
// Respect cancellation in loops and long operations
func (w *Worker) ProcessBatch(ctx context.Context, items []Item) error {
    for _, item := range items {
        select {
        case <-ctx.Done():
            return ctx.Err()  // stop cleanly on cancel
        default:
        }

        if err := w.process(ctx, item); err != nil {
            return fmt.Errorf("process item %s: %w", item.ID, err)
        }
    }
    return nil
}
```

---

## 5. Concurrency Patterns

### Goroutine ownership — every goroutine has an owner

```go
// Use errgroup — owner waits, errors propagate, context cancels all
g, ctx := errgroup.WithContext(ctx)

g.Go(func() error { return httpServer.Start(ctx) })
g.Go(func() error { return grpcServer.Start(ctx) })
g.Go(func() error { return kafkaConsumer.Run(ctx) })

if err := g.Wait(); err != nil {
    slog.Error("server error", "err", err)
}
```

### Worker pool

```go
func WorkerPool(ctx context.Context, workers int, jobs <-chan Job, process func(Job) error) error {
    g, ctx := errgroup.WithContext(ctx)

    for range workers {
        g.Go(func() error {
            for {
                select {
                case job, ok := <-jobs:
                    if !ok {
                        return nil  // channel closed — worker exits
                    }
                    if err := process(job); err != nil {
                        return err  // cancels all other workers via context
                    }
                case <-ctx.Done():
                    return ctx.Err()
                }
            }
        })
    }

    return g.Wait()
}

// Usage
jobs := make(chan Job, 100)
go func() {
    defer close(jobs)
    for _, j := range allJobs {
        jobs <- j
    }
}()

if err := WorkerPool(ctx, 10, jobs, processJob); err != nil {
    slog.Error("worker pool failed", "err", err)
}
```

### Pipeline

```go
func generate(ctx context.Context, items []string) <-chan string {
    out := make(chan string)
    go func() {
        defer close(out)
        for _, item := range items {
            select {
            case out <- item:
            case <-ctx.Done():
                return
            }
        }
    }()
    return out
}

func transform(ctx context.Context, in <-chan string) <-chan Result {
    out := make(chan Result)
    go func() {
        defer close(out)
        for s := range in {
            select {
            case out <- process(s):
            case <-ctx.Done():
                return
            }
        }
    }()
    return out
}

// Usage: chain stages
raw := generate(ctx, items)
results := transform(ctx, raw)
for r := range results {
    fmt.Println(r)
}
```

### Fan-out / fan-in

```go
// Fan-out: distribute work across N workers
func fanOut[T any](ctx context.Context, in <-chan T, workers int, fn func(T) error) []<-chan error {
    errs := make([]<-chan error, workers)
    for i := range workers {
        ch := make(chan error, 1)
        errs[i] = ch
        go func() {
            defer close(ch)
            for item := range in {
                if err := fn(item); err != nil {
                    ch <- err
                    return
                }
            }
        }()
    }
    return errs
}

// Fan-in: merge multiple channels into one
func fanIn[T any](ctx context.Context, channels ...<-chan T) <-chan T {
    merged := make(chan T)
    var wg sync.WaitGroup

    forward := func(ch <-chan T) {
        defer wg.Done()
        for v := range ch {
            select {
            case merged <- v:
            case <-ctx.Done():
                return
            }
        }
    }

    wg.Add(len(channels))
    for _, ch := range channels {
        go forward(ch)
    }

    go func() {
        wg.Wait()
        close(merged)
    }()

    return merged
}
```

### Singleflight — deduplicate concurrent requests

```go
import "golang.org/x/sync/singleflight"

type UserService struct {
    repo  UserRepository
    group singleflight.Group
}

func (s *UserService) GetByID(ctx context.Context, id string) (User, error) {
    v, err, _ := s.group.Do(id, func() (any, error) {
        return s.repo.GetByID(ctx, id)
    })
    if err != nil {
        return User{}, err
    }
    return v.(User), nil
}
```

Use singleflight when: multiple concurrent requests for the same key hit the DB simultaneously (thundering herd on cache miss).

### Semaphore — limit concurrency

```go
type Semaphore chan struct{}

func NewSemaphore(n int) Semaphore {
    return make(Semaphore, n)
}

func (s Semaphore) Acquire(ctx context.Context) error {
    select {
    case s <- struct{}{}:
        return nil
    case <-ctx.Done():
        return ctx.Err()
    }
}

func (s Semaphore) Release() {
    <-s
}

// Usage: limit to 5 concurrent DB queries
sem := NewSemaphore(5)

for _, id := range ids {
    if err := sem.Acquire(ctx); err != nil {
        return err
    }
    go func(id string) {
        defer sem.Release()
        result, _ := db.Get(ctx, id)
        // ...
    }(id)
}
```

### Channel patterns

```go
// Signal channel — use struct{}, never bool
done := make(chan struct{})
close(done)  // broadcast to all receivers — zero allocation

// Directional types in function signatures
func produce(out chan<- int) {}  // write only
func consume(in <-chan int)  {}  // read only

// Non-blocking send with overflow handling
select {
case ch <- event:
default:
    slog.Warn("event channel full, dropping event", "event", event)
}

// Timeout on receive
select {
case result := <-resultCh:
    handle(result)
case <-time.After(5 * time.Second):
    return ErrTimeout
case <-ctx.Done():
    return ctx.Err()
}
```

### sync primitives

```go
// Mutex — field placed directly above what it guards
type SafeMap struct {
    mu   sync.RWMutex
    data map[string]int
}

func (m *SafeMap) Set(k string, v int) {
    m.mu.Lock()
    defer m.mu.Unlock()
    m.data[k] = v
}

func (m *SafeMap) Get(k string) (int, bool) {
    m.mu.RLock()
    defer m.mu.RUnlock()
    v, ok := m.data[k]
    return v, ok
}

// sync.Once — guaranteed single initialization
var (
    instanceOnce sync.Once
    instance     *ExpensiveResource
)

func GetInstance() *ExpensiveResource {
    instanceOnce.Do(func() {
        instance = &ExpensiveResource{}
        instance.init()
    })
    return instance
}

// sync/atomic — counters and flags without mutex overhead
type Metrics struct {
    requestCount atomic.Int64
    errorCount   atomic.Int64
}

func (m *Metrics) IncRequest() { m.requestCount.Add(1) }
func (m *Metrics) Requests() int64 { return m.requestCount.Load() }
```

---

## 6. Generics

Go 1.18+ generics — use when it genuinely removes duplication. Avoid when it makes code harder to read.

### When to use generics

```go
// GOOD: collection/container utilities
func Map[T, U any](slice []T, fn func(T) U) []U {
    result := make([]U, len(slice))
    for i, v := range slice {
        result[i] = fn(v)
    }
    return result
}

func Filter[T any](slice []T, fn func(T) bool) []T {
    var result []T
    for _, v := range slice {
        if fn(v) {
            result = append(result, v)
        }
    }
    return result
}

func Reduce[T, U any](slice []T, initial U, fn func(U, T) U) U {
    result := initial
    for _, v := range slice {
        result = fn(result, v)
    }
    return result
}
```

### Type constraints

```go
import "golang.org/x/exp/constraints"

func Min[T constraints.Ordered](a, b T) T {
    if a < b {
        return a
    }
    return b
}

func Contains[T comparable](slice []T, target T) bool {
    for _, v := range slice {
        if v == target {
            return true
        }
    }
    return false
}

// Custom constraint
type Number interface {
    constraints.Integer | constraints.Float
}

func Sum[T Number](nums []T) T {
    var total T
    for _, n := range nums {
        total += n
    }
    return total
}
```

### Generic result type

```go
type Result[T any] struct {
    Value T
    Err   error
}

func OK[T any](v T) Result[T]    { return Result[T]{Value: v} }
func Fail[T any](err error) Result[T] { return Result[T]{Err: err} }

func (r Result[T]) Unwrap() (T, error) { return r.Value, r.Err }
```

### Generic repository base

```go
type Repository[T any, ID comparable] interface {
    GetByID(ctx context.Context, id ID) (T, error)
    Create(ctx context.Context, entity T) error
    Update(ctx context.Context, entity T) error
    Delete(ctx context.Context, id ID) error
    List(ctx context.Context, opts ListOptions) ([]T, error)
}
```

### When NOT to use generics

```go
// Bad — interface{} replaced with generic doesn't help if type is always known
func Process[T any](v T) { ... }  // just use the concrete type

// Bad — generics for 1-2 types: just duplicate the small function
// Good — generics when you have 5+ duplicate implementations of the same pattern
```

---

## 7. Memory Model & Runtime Internals

### Escape analysis

Understanding whether values escape to the heap affects allocation rate:

```go
// Does NOT escape — lives on stack
func sumInts(nums []int) int {
    total := 0  // stack allocated
    for _, n := range nums {
        total += n
    }
    return total
}

// DOES escape — pointer returned, moves to heap
func newUser(name string) *User {
    u := User{Name: name}  // escapes to heap because pointer is returned
    return &u
}

// Check with: go build -gcflags="-m" ./...
// Look for: "moved to heap: u"
```

### Garbage collector tuning

```go
// GOGC — controls GC trigger threshold (default: 100 = run GC when heap doubles)
// Lower = more frequent GC, lower memory, higher CPU
// Higher = less GC, higher memory, lower CPU

// For latency-sensitive services: increase GOGC (less GC pauses)
// GOGC=200 — run GC when heap grows 200% above live set

// Go 1.19+ GOMEMLIMIT — set a soft memory limit
// GOMEMLIMIT=1GiB — GC triggers aggressively before OOM kill
// Combine with higher GOGC for minimal GC with bounded memory
runtime/debug.SetMemoryLimit(1024 * 1024 * 1024)
```

### GOMAXPROCS

```go
// Default: number of logical CPUs
// For containerized workloads, set to match CPU limits:
import _ "go.uber.org/automaxprocs"  // auto-reads cgroup limits

// Manual:
runtime.GOMAXPROCS(runtime.NumCPU())
```

### sync.Pool — reuse allocations

```go
var jsonBufPool = sync.Pool{
    New: func() any {
        return new(bytes.Buffer)
    },
}

func marshalJSON(v any) ([]byte, error) {
    buf := jsonBufPool.Get().(*bytes.Buffer)
    defer func() {
        buf.Reset()
        jsonBufPool.Put(buf)
    }()

    if err := json.NewEncoder(buf).Encode(v); err != nil {
        return nil, err
    }
    return bytes.Clone(buf.Bytes()), nil  // clone before returning buf to pool
}
```

Pool items can be GC'd between uses — never assume an item from Get() is the one you Put() back.

---

## 8. Performance & Profiling

### pprof in production

```go
// Expose pprof on a separate internal-only port
import _ "net/http/pprof"

go func() {
    slog.Info("pprof listening", "addr", ":6060")
    http.ListenAndServe(":6060", nil)
}()
```

Collect profiles:

```bash
# CPU profile (30 seconds)
go tool pprof http://localhost:6060/debug/pprof/profile?seconds=30

# Heap profile
go tool pprof http://localhost:6060/debug/pprof/heap

# Goroutine dump (detect leaks)
curl http://localhost:6060/debug/pprof/goroutine?debug=2

# Trace (1 second)
curl http://localhost:6060/debug/pprof/trace?seconds=1 > trace.out
go tool trace trace.out
```

### Benchmarking

```go
func BenchmarkJSONMarshal(b *testing.B) {
    u := User{ID: "123", Email: "test@example.com", Name: "Test User"}
    b.ResetTimer()

    b.Run("stdlib", func(b *testing.B) {
        for b.Loop() {  // Go 1.24+: b.Loop() preferred over b.N loop
            json.Marshal(u)
        }
    })

    b.Run("sonic", func(b *testing.B) {
        for b.Loop() {
            sonic.Marshal(u)
        }
    })
}
```

```bash
go test -bench=. -benchmem -benchtime=5s ./...
go test -bench=BenchmarkJSONMarshal -count=5 ./... | benchstat /dev/stdin
```

### Pre-allocate slices

```go
// BAD — O(n) reallocations
var results []User
for _, id := range ids {
    u, _ := repo.Get(ctx, id)
    results = append(results, u)
}

// GOOD — one allocation
results := make([]User, 0, len(ids))
for _, id := range ids {
    u, _ := repo.Get(ctx, id)
    results = append(results, u)
}
```

### String building

```go
// BAD — O(n²) allocations
s := ""
for _, part := range parts {
    s += part  // new allocation each time
}

// GOOD — one allocation
var sb strings.Builder
sb.Grow(estimatedSize)
for _, part := range parts {
    sb.WriteString(part)
}
result := sb.String()
```

### Avoid interface boxing in hot paths

```go
// Slower — each item boxes to `any`, heap allocation
func processAny(items []any) {}

// Faster — concrete type, no boxing
func processUsers(users []User) {}

// With generics — concrete at compile time
func process[T User | Order | Product](items []T) {}
```

---

## 9. HTTP Server Architecture

### Server construction

```go
// internal/server/http.go
func NewHTTPServer(cfg *config.Config, handlers *Handlers) *http.Server {
    r := chi.NewRouter()

    // Layer middleware in the right order:
    // 1. Request ID — first, so everything that follows can log it
    // 2. Real IP — before logging
    // 3. Logger — after IP is resolved
    // 4. Recoverer — before business middleware (catch panics everywhere)
    // 5. Compression — outermost response wrapper
    // 6. CORS
    // 7. Timeout — last global, before route-specific
    r.Use(
        middleware.RequestID,
        middleware.RealIP,
        RequestLogger,
        Recoverer,
        middleware.Compress(5),
        cors.Handler(corsOptions(cfg)),
        middleware.Timeout(30*time.Second),
    )

    r.Get("/healthz", handlers.Health.Live)
    r.Get("/readyz",  handlers.Health.Ready)
    r.Handle("/metrics", promhttp.Handler())

    r.Route("/api/v1", func(r chi.Router) {
        r.Use(Auth(cfg.Auth))
        r.Use(RateLimit(cfg.RateLimit))

        r.Route("/users",    func(r chi.Router) { mountUserRoutes(r, handlers.User) })
        r.Route("/orders",   func(r chi.Router) { mountOrderRoutes(r, handlers.Order) })
    })

    return &http.Server{
        Addr:              fmt.Sprintf(":%d", cfg.HTTP.Port),
        Handler:           r,
        ReadTimeout:       cfg.HTTP.ReadTimeout,
        WriteTimeout:      cfg.HTTP.WriteTimeout,
        IdleTimeout:       cfg.HTTP.IdleTimeout,
        ReadHeaderTimeout: 5 * time.Second,
        MaxHeaderBytes:    1 << 20,  // 1 MB
    }
}
```

### Handler pattern — decode → validate → call → respond

```go
func (h *UserHandler) Create(w http.ResponseWriter, r *http.Request) {
    // 1. Decode
    var req CreateUserRequest
    if err := decodeJSON(r, &req); err != nil {
        respondError(w, http.StatusBadRequest, "invalid_json", err.Error())
        return
    }

    // 2. Validate at the boundary
    if errs := req.Validate(); len(errs) > 0 {
        respondValidationErrors(w, errs)
        return
    }

    // 3. Call business logic
    user, err := h.svc.CreateUser(r.Context(), req.toDomain())
    if err != nil {
        h.handleError(w, err)
        return
    }

    // 4. Respond
    respondJSON(w, http.StatusCreated, toUserResponse(user))
}
```

### Consistent response envelope

```go
// Success
type Response[T any] struct {
    Data T `json:"data"`
}

// List
type ListResponse[T any] struct {
    Data       []T    `json:"data"`
    NextCursor string `json:"next_cursor,omitempty"`
    Total      int    `json:"total"`
}

// Error
type ErrorResponse struct {
    Error ErrorDetail `json:"error"`
}

type ErrorDetail struct {
    Code    string         `json:"code"`
    Message string         `json:"message"`
    Details map[string]any `json:"details,omitempty"`
}

func respondJSON(w http.ResponseWriter, status int, data any) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    json.NewEncoder(w).Encode(data)
}

func respondError(w http.ResponseWriter, status int, code, msg string) {
    respondJSON(w, status, ErrorResponse{
        Error: ErrorDetail{Code: code, Message: msg},
    })
}
```

### HTTP client — never use http.DefaultClient in production

```go
// internal/httpclient/client.go
func New(opts ...Option) *http.Client {
    transport := &http.Transport{
        MaxIdleConns:        100,
        MaxIdleConnsPerHost: 10,
        IdleConnTimeout:     90 * time.Second,
        TLSHandshakeTimeout: 10 * time.Second,
        DisableCompression:  false,
    }

    client := &http.Client{
        Timeout:   30 * time.Second,
        Transport: transport,
    }

    for _, o := range opts {
        o(client)
    }
    return client
}
```

Always:
- Set `Timeout` on the client
- Reuse the client (share the transport pool)
- Close `resp.Body` after reading
- `io.Copy(io.Discard, resp.Body)` before close if you don't read the full body

---

## 10. gRPC & Streaming

### Server setup

```go
func NewGRPCServer(cfg *config.Config, services *Services) *grpc.Server {
    srv := grpc.NewServer(
        grpc.StatsHandler(otelgrpc.NewServerHandler()),
        grpc.ChainUnaryInterceptor(
            grpcrecovery.UnaryServerInterceptor(),
            grpclogging.UnaryServerInterceptor(logrusEntry),
            grpcauth.UnaryServerInterceptor(authFunc),
            grpcvalidate.UnaryServerInterceptor(),
        ),
        grpc.ChainStreamInterceptor(
            grpcrecovery.StreamServerInterceptor(),
            grpcauth.StreamServerInterceptor(authFunc),
        ),
        grpc.MaxRecvMsgSize(4*1024*1024),  // 4MB
        grpc.MaxSendMsgSize(4*1024*1024),
    )

    pb.RegisterUserServiceServer(srv, services.User)
    pb.RegisterOrderServiceServer(srv, services.Order)

    healthpb.RegisterHealthServer(srv, health.NewServer())

    if cfg.App.Env != "production" {
        reflection.Register(srv)
    }

    return srv
}
```

### Streaming patterns

```go
// Server-side streaming — send many responses to one request
func (s *OrderServer) WatchOrderUpdates(
    req *pb.WatchRequest,
    stream pb.OrderService_WatchOrderUpdatesServer,
) error {
    ctx := stream.Context()
    ch := s.orderEvents.Subscribe(req.OrderId)
    defer s.orderEvents.Unsubscribe(req.OrderId, ch)

    for {
        select {
        case event := <-ch:
            if err := stream.Send(toProtoEvent(event)); err != nil {
                return status.Errorf(codes.Internal, "send: %v", err)
            }
        case <-ctx.Done():
            return nil
        }
    }
}

// Client-side streaming — receive many requests, send one response
func (s *UploadServer) UploadChunks(stream pb.FileService_UploadChunksServer) error {
    var buf bytes.Buffer
    for {
        chunk, err := stream.Recv()
        if err == io.EOF {
            break
        }
        if err != nil {
            return status.Errorf(codes.Internal, "recv: %v", err)
        }
        buf.Write(chunk.Data)
    }

    fileID, err := s.storage.Save(stream.Context(), buf.Bytes())
    if err != nil {
        return status.Errorf(codes.Internal, "save: %v", err)
    }

    return stream.SendAndClose(&pb.UploadResponse{FileId: fileID})
}

// Bidirectional streaming — chat-like protocol
func (s *ChatServer) Chat(stream pb.ChatService_ChatServer) error {
    ctx := stream.Context()
    g, ctx := errgroup.WithContext(ctx)

    g.Go(func() error {  // reader goroutine
        for {
            msg, err := stream.Recv()
            if err == io.EOF || status.Code(err) == codes.Canceled {
                return nil
            }
            if err != nil {
                return err
            }
            s.broadcast(msg)
        }
    })

    g.Go(func() error {  // writer goroutine
        sub := s.subscribe(ctx)
        for msg := range sub {
            if err := stream.Send(msg); err != nil {
                return err
            }
        }
        return nil
    })

    return g.Wait()
}
```

### Deadline propagation — critical for microservices

```go
// gRPC automatically propagates deadlines across service calls
// The receiving service sees the remaining budget, not a fresh deadline

func (h *handler) PlaceOrder(ctx context.Context, req *pb.OrderRequest) (*pb.Order, error) {
    // ctx already has the deadline from the caller
    // Don't add a new timeout that's longer than what's left

    dl, ok := ctx.Deadline()
    if ok && time.Until(dl) < 100*time.Millisecond {
        return nil, status.Error(codes.DeadlineExceeded, "deadline too short to proceed")
    }

    // Propagate ctx to all downstream calls
    user, err := h.userClient.GetUser(ctx, &pb.GetUserRequest{Id: req.UserId})
    ...
}
```

---

## 11. WebSockets & SSE

### Server-Sent Events (SSE) — simpler than WebSockets for one-way push

```go
func (h *EventHandler) Stream(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-Type",  "text/event-stream")
    w.Header().Set("Cache-Control", "no-cache")
    w.Header().Set("Connection",    "keep-alive")
    w.Header().Set("X-Accel-Buffering", "no")  // disable nginx buffering

    flusher, ok := w.(http.Flusher)
    if !ok {
        http.Error(w, "streaming not supported", http.StatusInternalServerError)
        return
    }

    ctx := r.Context()
    events := h.bus.Subscribe(ctx)

    for {
        select {
        case event := <-events:
            data, _ := json.Marshal(event)
            fmt.Fprintf(w, "id: %s\n", event.ID)
            fmt.Fprintf(w, "event: %s\n", event.Type)
            fmt.Fprintf(w, "data: %s\n\n", data)
            flusher.Flush()

        case <-ctx.Done():
            return
        }
    }
}
```

### WebSockets with gorilla/websocket

```go
var upgrader = websocket.Upgrader{
    ReadBufferSize:  1024,
    WriteBufferSize: 1024,
    CheckOrigin: func(r *http.Request) bool {
        return isAllowedOrigin(r.Header.Get("Origin"))
    },
}

func (h *WSHandler) Handle(w http.ResponseWriter, r *http.Request) {
    conn, err := upgrader.Upgrade(w, r, nil)
    if err != nil {
        slog.ErrorContext(r.Context(), "websocket upgrade failed", "err", err)
        return
    }

    client := &WSClient{
        conn:   conn,
        send:   make(chan []byte, 256),
        userID: userIDFromContext(r.Context()),
    }

    h.hub.Register(client)
    defer h.hub.Unregister(client)

    g, ctx := errgroup.WithContext(r.Context())

    g.Go(func() error { return client.readPump(ctx) })   // read from ws
    g.Go(func() error { return client.writePump(ctx) })  // write to ws

    g.Wait()
}

func (c *WSClient) readPump(ctx context.Context) error {
    c.conn.SetReadLimit(512 * 1024)
    c.conn.SetReadDeadline(time.Now().Add(60 * time.Second))
    c.conn.SetPongHandler(func(string) error {
        c.conn.SetReadDeadline(time.Now().Add(60 * time.Second))
        return nil
    })

    for {
        _, msg, err := c.conn.ReadMessage()
        if err != nil {
            if websocket.IsCloseError(err, websocket.CloseNormalClosure, websocket.CloseGoingAway) {
                return nil
            }
            return err
        }
        c.hub.Broadcast(msg)
    }
}

func (c *WSClient) writePump(ctx context.Context) error {
    ticker := time.NewTicker(54 * time.Second)
    defer ticker.Stop()

    for {
        select {
        case msg, ok := <-c.send:
            c.conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
            if !ok {
                return c.conn.WriteMessage(websocket.CloseMessage, []byte{})
            }
            if err := c.conn.WriteMessage(websocket.TextMessage, msg); err != nil {
                return err
            }

        case <-ticker.C:
            c.conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
            if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
                return err
            }

        case <-ctx.Done():
            return nil
        }
    }
}
```

---

## 12. Middleware Engineering

### Request logger — structured, with trace ID

```go
func RequestLogger(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        ww := middleware.NewWrapResponseWriter(w, r.ProtoMajor)

        next.ServeHTTP(ww, r)

        slog.InfoContext(r.Context(), "request",
            "method",      r.Method,
            "path",        r.URL.Path,
            "status",      ww.Status(),
            "bytes",       ww.BytesWritten(),
            "duration_ms", time.Since(start).Milliseconds(),
            "request_id",  middleware.GetReqID(r.Context()),
            "user_agent",  r.UserAgent(),
            "remote_ip",   r.RemoteAddr,
        )
    })
}
```

### Panic recoverer — log stack trace, return 500

```go
func Recoverer(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        defer func() {
            if rec := recover(); rec != nil {
                buf := make([]byte, 4096)
                n := runtime.Stack(buf, false)
                slog.ErrorContext(r.Context(), "panic recovered",
                    "panic", rec,
                    "stack", string(buf[:n]),
                )
                respondError(w, http.StatusInternalServerError, "INTERNAL", "internal server error")
            }
        }()
        next.ServeHTTP(w, r)
    })
}
```

### CORS

```go
func corsOptions(cfg *config.Config) cors.Options {
    return cors.Options{
        AllowedOrigins:   cfg.HTTP.CORSAllowedOrigins,
        AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
        AllowedHeaders:   []string{"Authorization", "Content-Type", "X-Request-ID"},
        ExposedHeaders:   []string{"X-Request-ID"},
        AllowCredentials: true,
        MaxAge:           300,
    }
}
```

Never use `AllowedOrigins: []string{"*"}` with `AllowCredentials: true` — browsers block it and it's a security misconfiguration.

### Per-IP rate limiter with Redis

```go
func RateLimiter(rdb *redis.Client, limit int, window time.Duration) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            ip := r.RemoteAddr
            key := fmt.Sprintf("ratelimit:%s", ip)

            count, err := rdb.Incr(r.Context(), key).Result()
            if err != nil {
                next.ServeHTTP(w, r)  // fail open on Redis error
                return
            }
            if count == 1 {
                rdb.Expire(r.Context(), key, window)
            }

            w.Header().Set("X-RateLimit-Limit",     strconv.Itoa(limit))
            w.Header().Set("X-RateLimit-Remaining", strconv.Itoa(max(0, limit-int(count))))

            if int(count) > limit {
                w.Header().Set("Retry-After", strconv.Itoa(int(window.Seconds())))
                respondError(w, http.StatusTooManyRequests, "RATE_LIMIT_EXCEEDED", "too many requests")
                return
            }

            next.ServeHTTP(w, r)
        })
    }
}
```

---

## 13. API Design & Versioning

### URL versioning (preferred)

```
/api/v1/users       ← stable
/api/v2/users       ← new contract (run both simultaneously during migration)
```

Version in the URL makes it:
- Visible in logs and metrics
- Cacheable at the CDN layer
- Explicit to every consumer

### Pagination — cursor-based for large datasets

```go
type CursorPage[T any] struct {
    Items      []T    `json:"items"`
    NextCursor string `json:"next_cursor,omitempty"`
    HasMore    bool   `json:"has_more"`
}

// Cursor encodes: last-seen-id + sort-direction, base64-encoded
func encodeCursor(lastID string, createdAt time.Time) string {
    s := fmt.Sprintf("%s:%d", lastID, createdAt.UnixNano())
    return base64.URLEncoding.EncodeToString([]byte(s))
}

func decodeCursor(cursor string) (lastID string, createdAt time.Time, err error) {
    b, err := base64.URLEncoding.DecodeString(cursor)
    if err != nil {
        return "", time.Time{}, err
    }
    parts := strings.SplitN(string(b), ":", 2)
    // parse parts...
    return parts[0], time.Unix(0, nano), nil
}
```

### Request validation

```go
type CreateUserRequest struct {
    Email    string `json:"email"    validate:"required,email,max=254"`
    Name     string `json:"name"     validate:"required,min=1,max=100"`
    Role     string `json:"role"     validate:"required,oneof=admin user viewer"`
    Password string `json:"password" validate:"required,min=8,max=72"`
}

var validate = validator.New()

func (req *CreateUserRequest) Validate() []ValidationError {
    err := validate.Struct(req)
    if err == nil {
        return nil
    }

    var errs []ValidationError
    for _, fe := range err.(validator.ValidationErrors) {
        errs = append(errs, ValidationError{
            Field:   fe.Field(),
            Message: humanizeTag(fe.Tag()),
        })
    }
    return errs
}
```

---

## 14. Service Decomposition

### When to split — the right triggers

Split a monolith into a separate service **only when**:
1. The team scaling the context is distinct and needs independent deploys
2. The scaling profile differs substantially (the context is CPU-bound vs I/O-bound)
3. The failure of this context must not affect the rest of the system
4. The technology requirements genuinely differ (e.g., ML model server in Python)

A bounded context within one binary, cleanly separated by package boundaries, is almost always better than a premature split.

### Bounded context package layout

```
internal/
├── user/           ← User bounded context
│   ├── domain.go   # User entity, errors, events
│   ├── service.go  # use cases
│   ├── repo.go     # postgres implementation
│   ├── handler.go  # HTTP/gRPC handler
│   └── events.go   # domain events this context emits
├── order/          ← Order bounded context
│   └── ...
└── shared/         ← only universal primitives
    ├── money.go
    ├── pagination.go
    └── timeutil.go
```

Rules:
- `user/` never imports `order/` — communicate via events or interfaces
- `shared/` must not import any bounded context
- If something keeps getting added to `shared/`, it's a smell — it probably belongs to one context

---

## 15. Inter-Service Communication

### Synchronous — gRPC (service to service)

```go
// internal/client/userclient/client.go
type Client struct {
    conn pb.UserServiceClient
}

func New(target string, opts ...grpc.DialOption) (*Client, error) {
    base := []grpc.DialOption{
        grpc.WithTransportCredentials(insecure.NewCredentials()),
        grpc.WithStatsHandler(otelgrpc.NewClientHandler()),
        grpc.WithDefaultCallOptions(
            grpc.MaxCallRecvMsgSize(4*1024*1024),
        ),
        grpc.WithKeepaliveParams(keepalive.ClientParameters{
            Time:                10 * time.Second,
            Timeout:             time.Second,
            PermitWithoutStream: true,
        }),
    }

    conn, err := grpc.NewClient(target, append(base, opts...)...)
    if err != nil {
        return nil, err
    }

    return &Client{conn: pb.NewUserServiceClient(conn)}, nil
}

func (c *Client) GetUser(ctx context.Context, id string) (*domain.User, error) {
    resp, err := c.conn.GetUser(ctx, &pb.GetUserRequest{Id: id})
    if err != nil {
        if status.Code(err) == codes.NotFound {
            return nil, domain.ErrNotFound
        }
        return nil, fmt.Errorf("get user rpc: %w", err)
    }
    return fromProtoUser(resp), nil
}
```

### Async — event publishing

```go
type EventPublisher interface {
    Publish(ctx context.Context, topic string, event Event) error
}

type Event struct {
    ID          string         `json:"id"`
    Type        string         `json:"type"`
    OccurredAt  time.Time      `json:"occurred_at"`
    Data        map[string]any `json:"data"`
    TraceID     string         `json:"trace_id"`
}

func newEvent(eventType string, data map[string]any, ctx context.Context) Event {
    sc := trace.SpanFromContext(ctx).SpanContext()
    return Event{
        ID:         uuid.New().String(),
        Type:       eventType,
        OccurredAt: time.Now().UTC(),
        Data:       data,
        TraceID:    sc.TraceID().String(),
    }
}
```

---

## 16. Event-Driven Architecture

### Topic naming convention

```
{service}.{entity}.{event_type}.{version}

Examples:
user-service.user.created.v1
order-service.order.placed.v1
payment-service.payment.completed.v1
payment-service.payment.failed.v1
```

### Kafka producer — reliable publishing

```go
type KafkaPublisher struct {
    writer *kafka.Writer
}

func NewKafkaPublisher(brokers []string) *KafkaPublisher {
    return &KafkaPublisher{
        writer: &kafka.Writer{
            Addr:         kafka.TCP(brokers...),
            Balancer:     &kafka.Hash{},     // key-based partitioning for ordering
            RequiredAcks: kafka.RequireAll,   // all replicas must ack
            Async:        false,              // synchronous — caller knows if it failed
            Compression:  kafka.Snappy,
            BatchSize:    100,
            BatchTimeout: 10 * time.Millisecond,
        },
    }
}

func (p *KafkaPublisher) Publish(ctx context.Context, topic string, event Event) error {
    data, err := json.Marshal(event)
    if err != nil {
        return fmt.Errorf("marshal event: %w", err)
    }

    return p.writer.WriteMessages(ctx, kafka.Message{
        Topic: topic,
        Key:   []byte(event.ID),  // key = ID for idempotent partitioning
        Value: data,
        Headers: []kafka.Header{
            {Key: "trace-id", Value: []byte(event.TraceID)},
            {Key: "content-type", Value: []byte("application/json")},
        },
    })
}
```

### Kafka consumer — exactly-once semantics

```go
type Consumer struct {
    reader *kafka.Reader
    dlq    *kafka.Writer  // dead letter queue
}

func (c *Consumer) Consume(ctx context.Context, handler HandlerFunc) error {
    for {
        msg, err := c.reader.FetchMessage(ctx)
        if err != nil {
            if ctx.Err() != nil {
                return nil  // clean shutdown
            }
            return fmt.Errorf("fetch message: %w", err)
        }

        // Extract trace context from headers
        ctx := extractTraceContext(ctx, msg.Headers)

        if err := c.handleWithRetry(ctx, msg, handler); err != nil {
            slog.ErrorContext(ctx, "handler failed after retries, sending to DLQ",
                "topic", msg.Topic,
                "offset", msg.Offset,
                "err", err,
            )
            c.dlq.WriteMessages(ctx, kafka.Message{
                Value: msg.Value,
                Headers: append(msg.Headers,
                    kafka.Header{Key: "dlq-error", Value: []byte(err.Error())},
                    kafka.Header{Key: "dlq-topic", Value: []byte(msg.Topic)},
                ),
            })
        }

        // Commit after processing — "at least once" delivery
        c.reader.CommitMessages(ctx, msg)
    }
}

func (c *Consumer) handleWithRetry(ctx context.Context, msg kafka.Message, h HandlerFunc) error {
    var lastErr error
    for attempt := range 3 {
        if err := h(ctx, msg); err != nil {
            lastErr = err
            wait := time.Duration(attempt+1) * 500 * time.Millisecond
            select {
            case <-time.After(wait):
            case <-ctx.Done():
                return ctx.Err()
            }
            continue
        }
        return nil
    }
    return lastErr
}
```

### Idempotency — consumer must be idempotent

```go
func (h *OrderHandler) HandlePaymentCompleted(ctx context.Context, msg kafka.Message) error {
    var event PaymentCompletedEvent
    if err := json.Unmarshal(msg.Value, &event); err != nil {
        return fmt.Errorf("unmarshal: %w", err)
    }

    // Use the event ID as idempotency key — stored in DB after first processing
    processed, err := h.repo.IsEventProcessed(ctx, event.ID)
    if err != nil {
        return fmt.Errorf("check idempotency: %w", err)
    }
    if processed {
        return nil  // already handled, skip
    }

    // Process in a transaction that also records the event ID
    return h.db.WithTx(ctx, func(tx pgx.Tx) error {
        if err := h.orders.MarkPaid(ctx, tx, event.OrderID); err != nil {
            return err
        }
        return h.repo.MarkEventProcessed(ctx, tx, event.ID)
    })
}
```

---

## 17. CQRS & Event Sourcing

### CQRS — separate read and write models

```go
// Write side — commands change state
type OrderCommandService struct {
    repo      OrderRepository
    publisher EventPublisher
}

func (s *OrderCommandService) PlaceOrder(ctx context.Context, cmd PlaceOrderCommand) (OrderID, error) {
    order := domain.NewOrder(cmd.UserID, cmd.Items)
    if err := order.Validate(); err != nil {
        return "", fmt.Errorf("validate order: %w", err)
    }

    if err := s.repo.Save(ctx, order); err != nil {
        return "", fmt.Errorf("save order: %w", err)
    }

    s.publisher.Publish(ctx, "order-service.order.placed.v1", orderPlacedEvent(order))
    return order.ID, nil
}

// Read side — queries return optimized projections
type OrderQueryService struct {
    readDB *pgxpool.Pool  // can be a read replica
}

type OrderSummary struct {
    ID        OrderID
    UserEmail string
    Status    string
    Total     money.Amount
    ItemCount int
    PlacedAt  time.Time
}

func (s *OrderQueryService) GetSummary(ctx context.Context, id OrderID) (OrderSummary, error) {
    // Query a denormalized read model — fast, no joins
    const q = `
        SELECT o.id, u.email, o.status, o.total_cents, o.item_count, o.placed_at
        FROM order_summaries o
        JOIN users u ON u.id = o.user_id
        WHERE o.id = $1`
    // ...
}
```

### Event sourcing — store events, derive state

```go
type OrderEvent struct {
    ID         string
    OrderID    OrderID
    Type       string
    Data       json.RawMessage
    OccurredAt time.Time
    Version    int
}

// Append-only event store
type EventStore interface {
    Append(ctx context.Context, aggregateID string, events []OrderEvent, expectedVersion int) error
    Load(ctx context.Context, aggregateID string) ([]OrderEvent, error)
}

// Rebuild order state from events
func ReplayOrder(events []OrderEvent) (*Order, error) {
    o := &Order{}
    for _, e := range events {
        if err := o.Apply(e); err != nil {
            return nil, fmt.Errorf("apply event %s: %w", e.Type, err)
        }
    }
    return o, nil
}

func (o *Order) Apply(e OrderEvent) error {
    switch e.Type {
    case "order.placed":
        var d OrderPlacedData
        json.Unmarshal(e.Data, &d)
        o.ID = OrderID(e.OrderID)
        o.Status = OrderStatusPlaced
        o.Items = d.Items

    case "order.paid":
        o.Status = OrderStatusPaid
        o.PaidAt = e.OccurredAt

    case "order.cancelled":
        o.Status = OrderStatusCancelled

    default:
        return fmt.Errorf("unknown event type: %s", e.Type)
    }
    o.Version = e.Version
    return nil
}
```

---

## 18. Saga Pattern

### Choreography saga — services react to events

```
OrderService  → publishes "order.placed"
PaymentService → subscribes, charges card → publishes "payment.completed" or "payment.failed"
InventoryService → subscribes to "payment.completed" → reserves stock → publishes "stock.reserved"
ShippingService → subscribes to "stock.reserved" → creates shipment
```

Compensating transactions on failure:
```
payment.failed → OrderService cancels the order
stock.reservation.failed → PaymentService refunds
```

```go
// PaymentService listens and acts
func (h *PaymentHandler) HandleOrderPlaced(ctx context.Context, msg kafka.Message) error {
    var event OrderPlacedEvent
    json.Unmarshal(msg.Value, &event)

    result, err := h.chargeCard(ctx, event.UserID, event.TotalCents)
    if err != nil {
        // Publish compensation event
        h.publisher.Publish(ctx, "payment-service.payment.failed.v1", PaymentFailedEvent{
            OrderID: event.OrderID,
            Reason:  err.Error(),
        })
        return nil  // not an error — we handled it with a compensation event
    }

    h.publisher.Publish(ctx, "payment-service.payment.completed.v1", PaymentCompletedEvent{
        OrderID:       event.OrderID,
        PaymentID:     result.ID,
        ChargedCents:  event.TotalCents,
    })
    return nil
}
```

### Orchestration saga — one coordinator controls the flow

```go
type OrderSaga struct {
    payment   PaymentClient
    inventory InventoryClient
    shipping  ShippingClient
    orders    OrderRepository
}

func (s *OrderSaga) Execute(ctx context.Context, orderID OrderID) error {
    order, err := s.orders.GetByID(ctx, orderID)
    if err != nil {
        return err
    }

    // Step 1: charge payment
    paymentID, err := s.payment.Charge(ctx, order.UserID, order.TotalCents)
    if err != nil {
        s.orders.UpdateStatus(ctx, orderID, "payment_failed")
        return fmt.Errorf("charge payment: %w", err)
    }

    // Step 2: reserve inventory
    if err := s.inventory.Reserve(ctx, order.Items); err != nil {
        // compensate: refund payment
        s.payment.Refund(ctx, paymentID)
        s.orders.UpdateStatus(ctx, orderID, "inventory_failed")
        return fmt.Errorf("reserve inventory: %w", err)
    }

    // Step 3: create shipment
    shipmentID, err := s.shipping.CreateShipment(ctx, order)
    if err != nil {
        // compensate: release inventory, refund payment
        s.inventory.Release(ctx, order.Items)
        s.payment.Refund(ctx, paymentID)
        s.orders.UpdateStatus(ctx, orderID, "shipping_failed")
        return fmt.Errorf("create shipment: %w", err)
    }

    s.orders.MarkConfirmed(ctx, orderID, paymentID, shipmentID)
    return nil
}
```

---

## 19. Resilience Patterns

### Circuit breaker

```go
import "github.com/sony/gobreaker"

type ResilientUserClient struct {
    client *UserClient
    cb     *gobreaker.CircuitBreaker
}

func NewResilientClient(client *UserClient) *ResilientUserClient {
    cb := gobreaker.NewCircuitBreaker(gobreaker.Settings{
        Name:        "user-service",
        MaxRequests: 3,           // allow 3 requests in half-open state
        Interval:    60 * time.Second,
        Timeout:     30 * time.Second,
        ReadyToTrip: func(counts gobreaker.Counts) bool {
            failureRatio := float64(counts.TotalFailures) / float64(counts.Requests)
            return counts.Requests >= 10 && failureRatio >= 0.5
        },
        OnStateChange: func(name string, from, to gobreaker.State) {
            slog.Warn("circuit breaker state change",
                "name", name, "from", from, "to", to)
        },
    })

    return &ResilientUserClient{client: client, cb: cb}
}

func (c *ResilientUserClient) GetUser(ctx context.Context, id string) (*User, error) {
    result, err := c.cb.Execute(func() (any, error) {
        return c.client.GetUser(ctx, id)
    })
    if err != nil {
        if err == gobreaker.ErrOpenState {
            return nil, ErrServiceUnavailable
        }
        return nil, err
    }
    return result.(*User), nil
}
```

### Retry with exponential backoff

```go
import "github.com/avast/retry-go/v4"

func (c *Client) GetUserWithRetry(ctx context.Context, id string) (*User, error) {
    var user *User

    err := retry.Do(
        func() error {
            var err error
            user, err = c.GetUser(ctx, id)
            return err
        },
        retry.Context(ctx),
        retry.Attempts(3),
        retry.Delay(100*time.Millisecond),
        retry.DelayType(retry.BackOffDelay),
        retry.MaxDelay(2*time.Second),
        retry.RetryIf(func(err error) bool {
            // Only retry transient errors
            code := status.Code(err)
            return code == codes.Unavailable || code == codes.DeadlineExceeded
        }),
        retry.OnRetry(func(n uint, err error) {
            slog.WarnContext(ctx, "retrying request", "attempt", n, "err", err)
        }),
    )

    return user, err
}
```

### Bulkhead — isolate resources per caller

```go
type BulkheadClient struct {
    pools map[string]chan struct{}
}

func (c *BulkheadClient) Execute(ctx context.Context, caller string, fn func() error) error {
    pool, ok := c.pools[caller]
    if !ok {
        pool = make(chan struct{}, 10)  // 10 concurrent requests per caller
        c.pools[caller] = pool
    }

    select {
    case pool <- struct{}{}:
        defer func() { <-pool }()
        return fn()
    case <-ctx.Done():
        return ctx.Err()
    default:
        return ErrBulkheadFull  // reject immediately when pool is full
    }
}
```

### Timeout budget pattern

```go
// Each service subtracts from a total budget, not adding its own
func (s *Service) HandleRequest(ctx context.Context, req Request) (Response, error) {
    deadline, ok := ctx.Deadline()
    if !ok {
        var cancel context.CancelFunc
        ctx, cancel = context.WithTimeout(ctx, 5*time.Second)
        defer cancel()
    }

    remaining := time.Until(deadline)
    if remaining < 50*time.Millisecond {
        return Response{}, ErrDeadlineTooShort
    }

    // Allocate 60% of remaining budget to downstream call
    downstreamCtx, cancel := context.WithTimeout(ctx, remaining*6/10)
    defer cancel()

    return s.downstream.Call(downstreamCtx, req)
}
```

---

## 20. Distributed Tracing & Correlation

### Trace context propagation

```go
// Inject trace context into outgoing HTTP calls
func (c *HTTPClient) Do(ctx context.Context, req *http.Request) (*http.Response, error) {
    otel.GetTextMapPropagator().Inject(ctx, propagation.HeaderCarrier(req.Header))
    return c.client.Do(req.WithContext(ctx))
}

// Extract trace context from incoming HTTP calls (done by otelhttp middleware)
// Extract from Kafka message headers
func extractTraceContext(ctx context.Context, headers []kafka.Header) context.Context {
    m := make(map[string]string)
    for _, h := range headers {
        m[h.Key] = string(h.Value)
    }
    return otel.GetTextMapPropagator().Extract(ctx, propagation.MapCarrier(m))
}
```

### Span attributes — what to add

```go
func (s *OrderService) PlaceOrder(ctx context.Context, cmd PlaceOrderCommand) (OrderID, error) {
    ctx, span := tracer.Start(ctx, "OrderService.PlaceOrder",
        trace.WithAttributes(
            attribute.String("user.id",        string(cmd.UserID)),
            attribute.Int("order.item_count",  len(cmd.Items)),
            attribute.Float64("order.total",   cmd.Total.Float64()),
        ),
    )
    defer span.End()

    orderID, err := s.createOrder(ctx, cmd)
    if err != nil {
        span.RecordError(err)
        span.SetStatus(codes.Error, err.Error())
        return "", err
    }

    span.SetAttributes(attribute.String("order.id", string(orderID)))
    return orderID, nil
}
```

### Correlation ID across services

Every request must carry a correlation ID from the edge all the way through. Add it to every log line and every outbound call:

```go
func CorrelationID(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        id := r.Header.Get("X-Correlation-ID")
        if id == "" {
            id = uuid.New().String()
        }

        ctx := context.WithValue(r.Context(), ctxKeyCorrelationID, id)
        w.Header().Set("X-Correlation-ID", id)

        // Add to logger context
        logger := slog.Default().With("correlation_id", id)
        ctx = contextWithLogger(ctx, logger)

        next.ServeHTTP(w, r.WithContext(ctx))
    })
}
```

---

## 21. Database Patterns at Scale

### Read replica routing

```go
type DB struct {
    primary *pgxpool.Pool
    replica *pgxpool.Pool
}

func (db *DB) Read() *pgxpool.Pool {
    if db.replica != nil {
        return db.replica
    }
    return db.primary
}

func (db *DB) Write() *pgxpool.Pool {
    return db.primary
}

// Repository uses Read() for queries, Write() for mutations
func (r *repo) GetByID(ctx context.Context, id string) (Entity, error) {
    return r.query(ctx, r.db.Read(), queryGetByID, id)
}

func (r *repo) Create(ctx context.Context, e Entity) error {
    return r.exec(ctx, r.db.Write(), queryInsert, e)
}
```

### Query timeout discipline

```go
func (r *repo) List(ctx context.Context, opts ListOptions) ([]Entity, error) {
    // Add per-query timeout on top of the request context
    qctx, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel()

    rows, err := r.db.Query(qctx, queryList, opts.Cursor, opts.Limit+1)
    if err != nil {
        return nil, fmt.Errorf("list query: %w", err)
    }
    defer rows.Close()
    // ...
}
```

### Soft deletes

```sql
ALTER TABLE users ADD COLUMN deleted_at TIMESTAMPTZ;
CREATE INDEX idx_users_active ON users(id) WHERE deleted_at IS NULL;
```

```go
// Always filter deleted records
const queryGetByID = `
    SELECT id, email, name, created_at, updated_at
    FROM users
    WHERE id = $1 AND deleted_at IS NULL`

// Soft delete
const querySoftDelete = `
    UPDATE users SET deleted_at = NOW() WHERE id = $1 AND deleted_at IS NULL`
```

### N+1 query prevention

```go
// BAD — N+1
orders, _ := repo.ListOrders(ctx)
for _, o := range orders {
    o.User, _ = repo.GetUser(ctx, o.UserID)  // 1 query per order
}

// GOOD — batch load
orders, _ := repo.ListOrders(ctx)

userIDs := make([]string, len(orders))
for i, o := range orders {
    userIDs[i] = string(o.UserID)
}

users, _ := repo.GetUsersByIDs(ctx, userIDs)  // 1 query total
userMap := indexByID(users)

for i := range orders {
    orders[i].User = userMap[orders[i].UserID]
}
```

---

## 22. Transaction Management

### Unit of Work pattern

```go
type TxFunc func(ctx context.Context, tx pgx.Tx) error

func (db *DB) WithTx(ctx context.Context, fn TxFunc) error {
    tx, err := db.primary.Begin(ctx)
    if err != nil {
        return fmt.Errorf("begin tx: %w", err)
    }

    if err := fn(ctx, tx); err != nil {
        if rbErr := tx.Rollback(ctx); rbErr != nil {
            return fmt.Errorf("rollback: %v (original: %w)", rbErr, err)
        }
        return err
    }

    if err := tx.Commit(ctx); err != nil {
        return fmt.Errorf("commit: %w", err)
    }
    return nil
}

// Usage
err := db.WithTx(ctx, func(ctx context.Context, tx pgx.Tx) error {
    if err := orderRepo.Create(ctx, tx, order); err != nil {
        return err
    }
    if err := inventoryRepo.Decrement(ctx, tx, order.Items); err != nil {
        return err
    }
    return eventStore.Append(ctx, tx, orderCreatedEvent(order))
})
```

### Optimistic locking — prevent lost updates

```go
// Schema: version column
// ALTER TABLE orders ADD COLUMN version INT NOT NULL DEFAULT 1;

func (r *repo) Update(ctx context.Context, order Order) error {
    result, err := r.db.Exec(ctx, `
        UPDATE orders
        SET status = $1, updated_at = NOW(), version = version + 1
        WHERE id = $2 AND version = $3`,
        order.Status, order.ID, order.Version,
    )
    if err != nil {
        return fmt.Errorf("update order: %w", err)
    }
    if result.RowsAffected() == 0 {
        return ErrConflict  // someone else updated first
    }
    return nil
}

// Caller retries on ErrConflict
for range 3 {
    order, err := repo.GetByID(ctx, id)
    if err != nil { return err }

    order.Status = OrderStatusShipped

    err = repo.Update(ctx, order)
    if errors.Is(err, ErrConflict) {
        continue  // re-read and retry
    }
    return err
}
return ErrMaxRetriesExceeded
```

---

## 23. Outbox Pattern

Reliably publish events without distributed transactions:

```sql
CREATE TABLE outbox (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    topic        TEXT NOT NULL,
    payload      JSONB NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    published_at TIMESTAMPTZ,
    attempts     INT NOT NULL DEFAULT 0
);
```

```go
// In the same transaction as the business operation
func (s *OrderService) PlaceOrder(ctx context.Context, cmd PlaceOrderCommand) error {
    return s.db.WithTx(ctx, func(ctx context.Context, tx pgx.Tx) error {
        order := domain.NewOrder(cmd)

        if err := s.orderRepo.Create(ctx, tx, order); err != nil {
            return err
        }

        // Write the event to outbox IN THE SAME TRANSACTION
        event, _ := json.Marshal(orderPlacedEvent(order))
        _, err := tx.Exec(ctx,
            `INSERT INTO outbox (topic, payload) VALUES ($1, $2)`,
            "order-service.order.placed.v1", event,
        )
        return err
    })
}

// Background relay: poll outbox and publish
func (r *OutboxRelay) Run(ctx context.Context) error {
    ticker := time.NewTicker(500 * time.Millisecond)
    defer ticker.Stop()

    for {
        select {
        case <-ticker.C:
            r.flush(ctx)
        case <-ctx.Done():
            return nil
        }
    }
}

func (r *OutboxRelay) flush(ctx context.Context) {
    rows, err := r.db.Query(ctx, `
        SELECT id, topic, payload FROM outbox
        WHERE published_at IS NULL AND attempts < 5
        ORDER BY created_at LIMIT 100
        FOR UPDATE SKIP LOCKED`)
    if err != nil {
        slog.ErrorContext(ctx, "outbox fetch", "err", err)
        return
    }
    defer rows.Close()

    for rows.Next() {
        var id, topic string
        var payload json.RawMessage
        rows.Scan(&id, &topic, &payload)

        if err := r.publisher.Publish(ctx, topic, payload); err != nil {
            r.db.Exec(ctx, `UPDATE outbox SET attempts = attempts + 1 WHERE id = $1`, id)
            continue
        }
        r.db.Exec(ctx, `UPDATE outbox SET published_at = NOW() WHERE id = $1`, id)
    }
}
```

`FOR UPDATE SKIP LOCKED` lets multiple relay instances run without stepping on each other.

---

## 24. Caching Strategies

### Cache-aside (lazy loading)

```go
func (r *CachedUserRepo) GetByID(ctx context.Context, id string) (User, error) {
    key := "user:" + id

    data, err := r.redis.Get(ctx, key).Bytes()
    if err == nil {
        var u User
        return u, json.Unmarshal(data, &u)
    }
    if !errors.Is(err, redis.Nil) {
        slog.WarnContext(ctx, "cache get error", "err", err)
        // fail open — fall through to DB
    }

    u, err := r.db.GetByID(ctx, id)
    if err != nil {
        return User{}, err
    }

    data, _ = json.Marshal(u)
    r.redis.Set(ctx, key, data, 5*time.Minute)

    return u, nil
}
```

### Write-through — update cache on write

```go
func (r *CachedUserRepo) Update(ctx context.Context, u User) error {
    if err := r.db.Update(ctx, u); err != nil {
        return err
    }

    key := "user:" + string(u.ID)
    data, _ := json.Marshal(u)
    r.redis.Set(ctx, key, data, 5*time.Minute)

    return nil
}
```

### Distributed lock with Redis

```go
func (r *Redis) AcquireLock(ctx context.Context, key string, ttl time.Duration) (bool, error) {
    ok, err := r.client.SetNX(ctx, "lock:"+key, "1", ttl).Result()
    return ok, err
}

func (r *Redis) ReleaseLock(ctx context.Context, key string) error {
    return r.client.Del(ctx, "lock:"+key).Err()
}

// Usage
acquired, err := redis.AcquireLock(ctx, "invoice:"+invoiceID, 30*time.Second)
if !acquired || err != nil {
    return ErrLockNotAcquired
}
defer redis.ReleaseLock(ctx, "invoice:"+invoiceID)
```

For production distributed locks, use `go-redsync/redsync` (Redlock algorithm across multiple Redis nodes).

---

## 25. Container Hardening

### Dockerfile — production-grade

```dockerfile
# syntax=docker/dockerfile:1

FROM golang:1.23-alpine AS builder
RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
ARG VERSION=dev
ARG COMMIT=unknown
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build \
    -ldflags="-s -w -X main.version=${VERSION} -X main.commit=${COMMIT} -extldflags '-static'" \
    -trimpath \
    -o /app/server \
    ./cmd/server

# Verify binary is static
RUN file /app/server | grep -q "statically linked"

FROM gcr.io/distroless/static-debian12:nonroot AS final

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /app/server /server
COPY --from=builder /app/migrations /migrations

USER nonroot:nonroot

EXPOSE 8080 9090

ENTRYPOINT ["/server"]
```

Key choices:
- `distroless/static:nonroot` — no shell, no package manager, no root, minimal CVE surface
- `-trimpath` — removes local filesystem paths from binary (security + reproducibility)
- `-extldflags '-static'` — fully static, no glibc dependency
- `-s -w` — strip debug info and DWARF tables → 30-40% smaller binary

### docker-compose for local development

```yaml
# docker-compose.yml
services:
  app:
    build: .
    ports: ["8080:8080", "6060:6060"]
    env_file: .env
    depends_on:
      postgres: {condition: service_healthy}
      redis:    {condition: service_healthy}
    volumes:
      - .:/app  # live reload with air

  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB:       myservice
      POSTGRES_USER:     user
      POSTGRES_PASSWORD: password
    ports:    ["5432:5432"]
    volumes:  [pgdata:/var/lib/postgresql/data]
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d myservice"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s

  kafka:
    image: confluentinc/cp-kafka:7.6.0
    environment:
      KAFKA_NODE_ID: 1
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:9092,CONTROLLER://0.0.0.0:9093
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://localhost:9092
      KAFKA_CONTROLLER_QUORUM_VOTERS: 1@localhost:9093
      CLUSTER_ID: MkU3OEVBNTcwNTJENDM2Qk
    ports: ["9092:9092"]

volumes:
  pgdata:
```

---

## 26. Kubernetes Production Setup

### Deployment — full production config

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myservice
  namespace: production
  labels:
    app: myservice
    version: "1.0.0"
spec:
  replicas: 3
  revisionHistoryLimit: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0    # never take a pod down before new one is ready
  selector:
    matchLabels:
      app: myservice
  template:
    metadata:
      labels:
        app: myservice
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port:   "8080"
        prometheus.io/path:   "/metrics"
    spec:
      serviceAccountName: myservice
      automountServiceAccountToken: false

      # Topology spread — distribute across zones
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app: myservice

      # Pod anti-affinity — don't schedule replicas on same node
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                labelSelector:
                  matchLabels:
                    app: myservice
                topologyKey: kubernetes.io/hostname

      securityContext:
        runAsNonRoot:   true
        runAsUser:      65532
        runAsGroup:     65532
        fsGroup:        65532
        seccompProfile:
          type: RuntimeDefault

      terminationGracePeriodSeconds: 30

      containers:
        - name: myservice
          image: ghcr.io/myorg/myservice:1.0.0
          imagePullPolicy: Always
          ports:
            - name: http
              containerPort: 8080
            - name: grpc
              containerPort: 9090
            - name: pprof
              containerPort: 6060

          envFrom:
            - configMapRef:
                name: myservice-config
            - secretRef:
                name: myservice-secrets

          resources:
            requests:
              cpu:    100m
              memory: 128Mi
            limits:
              cpu:    500m
              memory: 256Mi

          livenessProbe:
            httpGet:
              path: /healthz
              port: http
            initialDelaySeconds: 5
            periodSeconds:       10
            failureThreshold:    3

          readinessProbe:
            httpGet:
              path: /readyz
              port: http
            initialDelaySeconds: 5
            periodSeconds:       5
            failureThreshold:    3
            successThreshold:    1

          startupProbe:
            httpGet:
              path: /healthz
              port: http
            failureThreshold:    30   # 30 * 2s = 60s for startup
            periodSeconds:       2

          lifecycle:
            preStop:
              exec:
                # Give load balancer time to drain
                command: ["/bin/sh", "-c", "sleep 5"]

          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem:   true
            capabilities:
              drop: [ALL]

          volumeMounts:
            - name: tmp
              mountPath: /tmp

      volumes:
        - name: tmp
          emptyDir: {}
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: myservice-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: myservice
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myservice-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myservice
  minReplicas: 3
  maxReplicas: 50
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300    # don't scale down for 5 minutes
      policies:
        - type: Percent
          value: 25
          periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
        - type: Pods
          value: 4
          periodSeconds: 60
```

### Network policy — zero-trust

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: myservice-netpol
spec:
  podSelector:
    matchLabels:
      app: myservice
  policyTypes: [Ingress, Egress]
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: nginx-ingress
      ports:
        - port: 8080
    - from:
        - namespaceSelector:
            matchLabels:
              name: monitoring
      ports:
        - port: 8080   # Prometheus scrape
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: postgres
      ports:
        - port: 5432
    - to:
        - podSelector:
            matchLabels:
              app: redis
      ports:
        - port: 6379
    - ports:
        - port: 53     # DNS
          protocol: UDP
```

---

## 27. Observability Stack

### The three pillars

| Pillar  | Tool                          | What it answers                        |
|---------|-------------------------------|----------------------------------------|
| Logs    | Loki + Grafana                | What happened and when                 |
| Metrics | Prometheus + Grafana          | Is it healthy, is it fast              |
| Traces  | Tempo or Jaeger + Grafana     | Why is this request slow               |

### OTEL setup — one SDK, pluggable backends

```go
// internal/telemetry/setup.go
func Setup(ctx context.Context, cfg OTELConfig) (shutdown func(context.Context), err error) {
    res, err := resource.New(ctx,
        resource.WithFromEnv(),
        resource.WithProcess(),
        resource.WithOS(),
        resource.WithContainer(),
        resource.WithHost(),
        resource.WithAttributes(
            semconv.ServiceName(cfg.ServiceName),
            semconv.ServiceVersion(cfg.ServiceVersion),
            semconv.DeploymentEnvironment(cfg.Environment),
        ),
    )
    if err != nil {
        return nil, err
    }

    var shutdowns []func(context.Context) error

    // Trace provider
    if cfg.Endpoint != "" {
        traceExp, err := otlptracegrpc.New(ctx,
            otlptracegrpc.WithEndpoint(cfg.Endpoint),
            otlptracegrpc.WithInsecure(),
        )
        if err != nil {
            return nil, err
        }

        tp := sdktrace.NewTracerProvider(
            sdktrace.WithBatcher(traceExp,
                sdktrace.WithMaxExportBatchSize(512),
                sdktrace.WithBatchTimeout(5*time.Second),
            ),
            sdktrace.WithResource(res),
            sdktrace.WithSampler(sdktrace.ParentBased(
                sdktrace.TraceIDRatioBased(cfg.SamplingRatio),
            )),
        )
        otel.SetTracerProvider(tp)
        shutdowns = append(shutdowns, tp.Shutdown)
    }

    // Metric provider (Prometheus exporter)
    promExp, err := prometheus.New()
    if err != nil {
        return nil, err
    }
    mp := sdkmetric.NewMeterProvider(
        sdkmetric.WithReader(promExp),
        sdkmetric.WithResource(res),
    )
    otel.SetMeterProvider(mp)
    shutdowns = append(shutdowns, mp.Shutdown)

    otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(
        propagation.TraceContext{},
        propagation.Baggage{},
    ))

    return func(ctx context.Context) {
        for _, fn := range shutdowns {
            fn(ctx)
        }
    }, nil
}
```

### Custom metrics

```go
var (
    meter = otel.Meter("myservice")

    orderCreated, _  = meter.Int64Counter("orders.created.total",
        metric.WithDescription("Total orders created"))

    orderDuration, _ = meter.Float64Histogram("orders.processing.duration_seconds",
        metric.WithDescription("Order processing duration"),
        metric.WithExplicitBucketBoundaries(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5))

    activeOrders, _  = meter.Int64UpDownCounter("orders.active",
        metric.WithDescription("Currently active orders"))
)

func (s *OrderService) PlaceOrder(ctx context.Context, cmd PlaceOrderCommand) (OrderID, error) {
    start := time.Now()
    activeOrders.Add(ctx, 1)
    defer activeOrders.Add(ctx, -1)

    orderID, err := s.create(ctx, cmd)

    attrs := metric.WithAttributes(
        attribute.String("status", statusFromErr(err)),
        attribute.String("user_tier", string(cmd.UserTier)),
    )
    orderDuration.Record(ctx, time.Since(start).Seconds(), attrs)
    if err == nil {
        orderCreated.Add(ctx, 1, attrs)
    }

    return orderID, err
}
```

### SLO-based alerting (Prometheus rules)

```yaml
# prometheus/rules/myservice.yml
groups:
  - name: myservice.slos
    rules:
      # Error rate SLO: < 1% of requests should fail
      - alert: HighErrorRate
        expr: |
          (
            sum(rate(http_requests_total{service="myservice",status=~"5.."}[5m]))
            /
            sum(rate(http_requests_total{service="myservice"}[5m]))
          ) > 0.01
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Error rate {{ $value | humanizePercentage }} > 1%"

      # Latency SLO: p99 < 500ms
      - alert: HighLatency
        expr: |
          histogram_quantile(0.99,
            sum(rate(http_request_duration_seconds_bucket{service="myservice"}[5m])) by (le)
          ) > 0.5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "p99 latency {{ $value | humanizeDuration }} > 500ms"

      # Pod restarts
      - alert: PodCrashLooping
        expr: |
          rate(kube_pod_container_status_restarts_total{namespace="production",pod=~"myservice-.*"}[15m]) > 0
        for: 5m
        labels:
          severity: critical
```

---

## 28. CI/CD & GitOps

### GitHub Actions — full pipeline

```yaml
name: CI/CD

on:
  push:
    branches: [main]
  pull_request:

permissions:
  contents: read
  packages: write
  security-events: write

env:
  IMAGE: ghcr.io/${{ github.repository }}
  GO_VERSION: "1.23"

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_DB: testdb
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
        options: >-
          --health-cmd pg_isready
          --health-interval 5s
          --health-timeout 5s
          --health-retries 5
      redis:
        image: redis:7-alpine
        options: --health-cmd "redis-cli ping"
        ports: ["6379:6379"]

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-go@v5
        with:
          go-version: ${{ env.GO_VERSION }}
          cache: true

      - name: Verify go.mod tidy
        run: |
          go mod tidy
          git diff --exit-code go.mod go.sum

      - name: Lint
        uses: golangci/golangci-lint-action@v6

      - name: Vulnerability scan
        run: go run golang.org/x/vuln/cmd/govulncheck@latest ./...

      - name: Unit tests
        run: go test -race -count=1 -coverprofile=coverage.out ./...

      - name: Integration tests
        run: go test -tags=integration -race -count=1 ./...
        env:
          DB_DSN:    postgres://test:test@localhost:5432/testdb?sslmode=disable
          REDIS_DSN: redis://localhost:6379

      - name: Coverage gate
        run: |
          COVERAGE=$(go tool cover -func=coverage.out | grep total | awk '{print $3}' | tr -d '%')
          echo "Total coverage: $COVERAGE%"
          if awk "BEGIN{exit !($COVERAGE < 70)}"; then
            echo "Coverage $COVERAGE% below 70% threshold" && exit 1
          fi

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          file: coverage.out

  build-push:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    outputs:
      image-digest: ${{ steps.build.outputs.digest }}

    steps:
      - uses: actions/checkout@v4

      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - uses: docker/setup-buildx-action@v3

      - name: Build and push
        id: build
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: |
            ${{ env.IMAGE }}:${{ github.sha }}
            ${{ env.IMAGE }}:latest
          build-args: |
            VERSION=${{ github.sha }}
            COMMIT=${{ github.sha }}
          cache-from: type=gha
          cache-to:   type=gha,mode=max
          sbom: true
          provenance: true

      - name: Scan image
        uses: aquasecurity/trivy-action@master
        with:
          image-ref:  ${{ env.IMAGE }}:${{ github.sha }}
          exit-code:  "1"
          severity:   "CRITICAL"
          format:     sarif
          output:     trivy.sarif

      - name: Upload scan results
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: trivy.sarif

  deploy:
    needs: build-push
    runs-on: ubuntu-latest
    environment: production
    if: github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v4

      - name: Update image tag in GitOps repo
        run: |
          git clone https://x-access-token:${{ secrets.GITOPS_TOKEN }}@github.com/myorg/k8s-config /tmp/gitops
          cd /tmp/gitops
          sed -i "s|image:.*myservice.*|image: ${{ env.IMAGE }}:${{ github.sha }}|" \
            deployments/production/myservice/deployment.yaml
          git config user.email "ci@myorg.com"
          git config user.name "CI"
          git commit -am "chore: deploy myservice ${{ github.sha }}"
          git push
```

### GitOps with ArgoCD

```yaml
# argocd/application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myservice
  namespace: argocd
spec:
  project: production
  source:
    repoURL: https://github.com/myorg/k8s-config
    targetRevision: main
    path: deployments/production/myservice
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune:    true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 3
      backoff:
        duration:    5s
        maxDuration: 3m
        factor:      2
```

---

## 29. Security in Depth

### JWT — use RS256 or EdDSA, not HS256

```go
// Generate EdDSA key pair (once, store private key in Vault)
_, privKey, _ := ed25519.GenerateKey(rand.Reader)

// Sign
token := jwt.NewWithClaims(jwt.SigningMethodEdDSA, jwt.MapClaims{
    "sub": userID,
    "iat": time.Now().Unix(),
    "exp": time.Now().Add(15 * time.Minute).Unix(),
    "jti": uuid.New().String(),  // JWT ID — allows revocation
})
signed, _ := token.SignedString(privKey)

// Verify (with public key only — distribute, never private key)
token, err := jwt.Parse(signed, func(t *jwt.Token) (any, error) {
    if _, ok := t.Method.(*jwt.SigningMethodEd25519); !ok {
        return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
    }
    return pubKey, nil
})
```

### Secret rotation — never restart for rotation

```go
// Use a key rotator that holds current + previous key
type KeyRotator struct {
    mu      sync.RWMutex
    current []byte
    previous []byte
}

func (kr *KeyRotator) Rotate(newKey []byte) {
    kr.mu.Lock()
    defer kr.mu.Unlock()
    kr.previous = kr.current
    kr.current = newKey
}

func (kr *KeyRotator) Verify(token string) (*Claims, error) {
    kr.mu.RLock()
    keys := [][]byte{kr.current, kr.previous}
    kr.mu.RUnlock()

    for _, key := range keys {
        if claims, err := parseJWT(token, key); err == nil {
            return claims, nil
        }
    }
    return nil, ErrInvalidToken
}
```

### SQL injection prevention

```go
// ALWAYS use parameterized queries
// Safe
row := db.QueryRow(ctx, "SELECT id FROM users WHERE email = $1", email)

// UNSAFE — never do this
query := fmt.Sprintf("SELECT id FROM users WHERE email = '%s'", email)
row := db.QueryRow(ctx, query)
```

### Security headers

```go
func SecurityHeaders(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("X-Content-Type-Options",            "nosniff")
        w.Header().Set("X-Frame-Options",                   "DENY")
        w.Header().Set("X-XSS-Protection",                  "1; mode=block")
        w.Header().Set("Referrer-Policy",                   "strict-origin-when-cross-origin")
        w.Header().Set("Permissions-Policy",                "camera=(), microphone=(), geolocation=()")
        w.Header().Set("Strict-Transport-Security",         "max-age=63072000; includeSubDomains")
        w.Header().Set("Content-Security-Policy",
            "default-src 'self'; script-src 'self'; style-src 'self'")
        next.ServeHTTP(w, r)
    })
}
```

### Security checklist

```
[ ] No secrets in code, logs, or environment variable names visible in PS output
[ ] Parameterized queries everywhere — grep for fmt.Sprintf + sql or raw string concat
[ ] JWT: RS256 or EdDSA; HS256 only if single-service and key rotated regularly
[ ] Passwords: bcrypt cost >= 12 or argon2id
[ ] All outbound HTTP clients have explicit timeouts — grep for http.DefaultClient
[ ] TLS 1.2+ minimum; TLS 1.3 preferred; cipher suites restricted
[ ] mTLS between internal services (service mesh or cert-manager issued certs)
[ ] govulncheck runs in CI and blocks on HIGH/CRITICAL
[ ] trivy image scan blocks on CRITICAL CVEs
[ ] Container: non-root user, read-only filesystem, all capabilities dropped
[ ] RBAC in Kubernetes: least privilege, no cluster-admin for workloads
[ ] Network policies: deny all by default, allow only required traffic
[ ] Rate limiting on every public endpoint
[ ] API keys and tokens never logged — use redacted summary structs
[ ] CORS: explicit allowed origins, never wildcard in production
[ ] Input validation at every HTTP boundary (not just frontend)
[ ] Dependency audit: go list -m all | nancy or govulncheck quarterly
```

---

## 30. Operational Runbooks

### Service is down

```
1. Check pod status:     kubectl get pods -n production -l app=myservice
2. Check recent logs:    kubectl logs -n production -l app=myservice --tail=100
3. Check events:         kubectl describe pod -n production <pod-name>
4. Check HPA:            kubectl get hpa -n production myservice-hpa
5. Check readiness:      curl https://myservice.internal/readyz | jq .
6. Check DB connections: kubectl exec -it <pod> -- curl localhost:8080/readyz
7. Rollback if needed:   kubectl rollout undo deployment/myservice -n production
8. Check error rate:     Grafana → myservice dashboard → Error Rate panel
```

### High memory usage

```
1. Check memory profile: kubectl exec -it <pod> -- curl localhost:6060/debug/pprof/heap > heap.out
                         go tool pprof heap.out
2. Check goroutine count: curl localhost:6060/debug/pprof/goroutine?debug=1 | head -50
3. Check for goroutine leaks: goroutine count should be stable under stable load
4. GOGC tuning: if GC is frequent, increase GOGC; set GOMEMLIMIT to pod limit
5. Check for large caches: look for unbounded maps or slices
```

### High latency

```
1. Check p99:    Grafana → latency panel, break down by endpoint
2. Check traces: Grafana Tempo → filter by high-duration traces
3. Check DB:     Postgres logs (log_min_duration_statement = 100ms)
                 pg_stat_activity for long-running queries
                 pg_stat_statements for slow query patterns
4. CPU profile:  curl localhost:6060/debug/pprof/profile?seconds=30 > cpu.out
                 go tool pprof cpu.out
5. Check external deps: downstream service latency via traces
6. Check connection pool: DB pool exhaustion causes queueing
```

### Database connection pool exhaustion

```
1. Check current connections: SELECT count(*) FROM pg_stat_activity;
2. Check pool stats in metrics: db_pool_idle, db_pool_in_use, db_pool_wait
3. Immediate relief: increase DB_MAX_OPEN_CONNS temporarily
4. Root cause: check for long-running transactions or leaked connections
   SELECT pid, query, state, query_start FROM pg_stat_activity
   WHERE state != 'idle' ORDER BY query_start;
5. Kill stuck connections if needed:
   SELECT pg_terminate_backend(pid) FROM pg_stat_activity
   WHERE query_start < NOW() - INTERVAL '5 minutes' AND state = 'active';
```

---

## Quick Reference — Decisions at a Glance

| Decision | Choice | Why |
|---|---|---|
| HTTP router | `chi` | stdlib-compatible, middleware chain, grouping |
| gRPC | `google.golang.org/grpc` | standard, OTEL-instrumented |
| Database driver | `pgx/v5` | best Postgres performance, typed API |
| Migrations | `goose` or `golang-migrate` | pick one, never mix |
| SQL queries | `sqlc` for complex, raw for simple | type-safe, no ORM overhead |
| Config | `cleanenv` | env + file + validation |
| Logging | `log/slog` | stdlib, structured, zero dependency |
| Metrics | OTEL → Prometheus | vendor-neutral, industry standard |
| Tracing | OTEL → Tempo/Jaeger | same SDK, swap backends |
| Auth | JWT EdDSA or RS256 | asymmetric — distribute public key only |
| Caching | `go-redis/v9` | best Go Redis client |
| Events | Kafka (`segmentio/kafka-go`) | durable, replayable |
| DI | Manual → `wire` when large | compile-time, no reflection |
| Testing | `testify` + `testcontainers` | real dependencies, hermetic |
| Mocks | `uber-go/mock` | type-safe, generated |
| Linter | `golangci-lint` | aggregates 50+ linters |
| Container base | `distroless/static:nonroot` | minimal attack surface |
| CI | GitHub Actions | native GHCR, SARIF upload |
| GitOps | ArgoCD | declarative, self-healing |

---

*Built from Go conventions, codebase guidelines, microservice bootstrap patterns, and production operational experience. Apply progressively — start simple, add complexity only when you have the problem it solves.*
