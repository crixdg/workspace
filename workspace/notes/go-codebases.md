# Go Codebase Guidelines — Modern Server / System (2026)

A comprehensive reference for structuring, building, and maintaining production-grade Go backend systems. Applies to microservices, monoliths, and everything in between.

---

## Table of Contents

1. [Project Layout](#1-project-layout)
2. [Module and Dependency Management](#2-module-and-dependency-management)
3. [Entry Points — cmd/](#3-entry-points--cmd)
4. [Internal Package Architecture](#4-internal-package-architecture)
5. [Configuration](#5-configuration)
6. [HTTP Layer](#6-http-layer)
7. [gRPC Layer](#7-grpc-layer)
8. [Database Layer](#8-database-layer)
9. [Domain / Business Logic Layer](#9-domain--business-logic-layer)
10. [Error Handling](#10-error-handling)
11. [Logging and Observability](#11-logging-and-observability)
12. [Testing Strategy](#12-testing-strategy)
13. [Background Workers and Jobs](#13-background-workers-and-jobs)
14. [Event-Driven Architecture](#14-event-driven-architecture)
15. [Authentication and Authorization](#15-authentication-and-authorization)
16. [Caching](#16-caching)
17. [Graceful Shutdown](#17-graceful-shutdown)
18. [Docker and Deployment](#18-docker-and-deployment)
19. [CI/CD Pipeline](#19-cicd-pipeline)
20. [Security Checklist](#20-security-checklist)
21. [Common Toolchain](#21-common-toolchain)

---

## 1. Project Layout

The canonical Go project layout for a backend service. Never put everything flat in the root.

```
my-service/
├── cmd/
│   ├── server/
│   │   └── main.go          # HTTP/gRPC server binary
│   └── worker/
│       └── main.go          # Background worker binary (if separate process)
│
├── internal/                # Private application code — not importable externally
│   ├── domain/              # Core business entities and interfaces
│   ├── service/             # Use-case / application logic
│   ├── handler/             # HTTP handlers (thin layer only)
│   ├── grpc/                # gRPC server implementations
│   ├── repository/          # Data access implementations
│   ├── middleware/           # HTTP/gRPC middleware
│   ├── worker/              # Background job implementations
│   └── event/               # Event consumers and producers
│
├── pkg/                     # Library code safe for external import
│   ├── apierr/              # Typed API error definitions
│   ├── pagination/          # Cursor/offset pagination helpers
│   ├── validator/           # Input validation
│   └── ptr/                 # Generic pointer helpers
│
├── api/
│   ├── openapi/
│   │   └── v1.yaml          # OpenAPI 3.1 spec (source of truth)
│   └── proto/
│       └── v1/              # Protobuf definitions
│
├── config/
│   ├── config.go            # Config struct, loader
│   └── config_test.go
│
├── migrations/
│   ├── 001_init.up.sql
│   ├── 001_init.down.sql
│   └── ...
│
├── scripts/
│   ├── seed/
│   │   └── main.go          # Dev seed data
│   └── tools.go             # go:generate and tool pinning
│
├── docker/
│   ├── Dockerfile
│   └── docker-compose.yml
│
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── release.yml
│
├── .golangci.yml            # Linter configuration
├── .env.example             # All required env vars, documented
├── buf.yaml                 # Protobuf lint/breaking config (if using gRPC)
├── buf.gen.yaml
├── Makefile
├── go.mod
└── go.sum
```

### Rules

- `internal/` is enforced by the Go toolchain — external packages cannot import it.
- `pkg/` should only contain code that is genuinely reusable across services. When in doubt, put it in `internal/`.
- Avoid a top-level `utils/` or `helpers/` package — name packages by what they provide, not what they are.
- One binary per `cmd/<name>/main.go`. Keep `main.go` under ~50 lines; all real wiring goes into a `run()` function or an `app` package.
- Generated files (protobuf, mocks, OpenAPI stubs) live with their package, not in a separate `gen/` root.

---

## 2. Module and Dependency Management

```
go.mod  ← always committed
go.sum  ← always committed, never hand-edited
```

### go.mod conventions

```go
module github.com/org/my-service

go 1.24  // always pin to current minor, update on each release cycle

require (
    // group: stdlib-adjacent
    golang.org/x/sync v0.10.0

    // group: web framework / routing
    github.com/go-chi/chi/v5 v5.2.1

    // group: database
    github.com/jackc/pgx/v5  v5.7.2
    github.com/pressly/goose/v3 v3.24.0

    // group: observability
    go.opentelemetry.io/otel v1.34.0

    // group: testing (keep separate from prod deps when possible)
    github.com/stretchr/testify v1.10.0
)
```

### Dependency hygiene

- `go mod tidy` in CI — fail if `go.mod` / `go.sum` are dirty after tidy.
- Pin tool dependencies via `tools.go`:

```go
//go:build tools

package tools

import (
    _ "github.com/golangci/golangci-lint/cmd/golangci-lint"
    _ "github.com/vektra/mockery/v2"
    _ "github.com/pressly/goose/v3/cmd/goose"
    _ "github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen"
)
```

- Use `go install tool@version` in CI — never rely on globally installed tools.
- Audit dependencies quarterly with `govulncheck ./...`.

---

## 3. Entry Points — cmd/

`main.go` should only bootstrap — no logic.

```go
// cmd/server/main.go
package main

import (
    "context"
    "log/slog"
    "os"
    "os/signal"
    "syscall"

    "github.com/org/my-service/internal/app"
)

func main() {
    ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
    defer stop()

    if err := app.Run(ctx, os.Args, os.Stdout); err != nil {
        slog.Error("server exited with error", "err", err)
        os.Exit(1)
    }
}
```

```go
// internal/app/app.go
package app

import (
    "context"
    "fmt"
    "io"
    "net/http"

    "github.com/org/my-service/config"
    "github.com/org/my-service/internal/handler"
    "github.com/org/my-service/internal/repository/postgres"
    "github.com/org/my-service/internal/service"
)

func Run(ctx context.Context, args []string, stdout io.Writer) error {
    cfg, err := config.Load()
    if err != nil {
        return fmt.Errorf("load config: %w", err)
    }

    db, err := postgres.Connect(ctx, cfg.DatabaseURL)
    if err != nil {
        return fmt.Errorf("connect db: %w", err)
    }
    defer db.Close()

    repo := postgres.NewAccountRepository(db)
    svc  := service.NewAccountService(repo)
    srv  := handler.NewServer(cfg, svc)

    return srv.Start(ctx)
}
```

---

## 4. Internal Package Architecture

### Layering (strict — no skipping layers)

```
cmd/server/main.go
    └── internal/app            ← wiring / DI root
            ├── internal/handler    ← HTTP/gRPC: parse → call service → respond
            │       └── internal/service   ← use cases / business logic
            │               └── internal/domain    ← entities, value objects, errors
            │               └── internal/repository (interface)
            │                       └── internal/repository/postgres  ← DB impl
            └── pkg/*           ← shared utilities
```

### Domain package

Owns the core types. Zero framework imports.

```go
// internal/domain/account.go
package domain

import (
    "errors"
    "time"
)

type AccountID string
type AccountStatus string

const (
    AccountStatusActive    AccountStatus = "active"
    AccountStatusSuspended AccountStatus = "suspended"
)

type Account struct {
    ID        AccountID
    Email     string
    Status    AccountStatus
    CreatedAt time.Time
    UpdatedAt time.Time
}

// Domain errors — typed for handler mapping
var (
    ErrAccountNotFound    = errors.New("account not found")
    ErrEmailAlreadyTaken  = errors.New("email already taken")
    ErrAccountSuspended   = errors.New("account is suspended")
)
```

### Repository interface

Defined in the domain or service layer — NOT in the repository implementation package.

```go
// internal/domain/repository.go
package domain

import "context"

type AccountRepository interface {
    Create(ctx context.Context, acc Account) error
    GetByID(ctx context.Context, id AccountID) (Account, error)
    GetByEmail(ctx context.Context, email string) (Account, error)
    Update(ctx context.Context, acc Account) error
    Delete(ctx context.Context, id AccountID) error
    List(ctx context.Context, opts ListOptions) ([]Account, error)
}

type ListOptions struct {
    Cursor string
    Limit  int
}
```

### Service layer

Business logic. Depends on interfaces, not concrete types.

```go
// internal/service/account.go
package service

import (
    "context"
    "fmt"

    "github.com/org/my-service/internal/domain"
)

type AccountService struct {
    repo domain.AccountRepository
}

func NewAccountService(repo domain.AccountRepository) *AccountService {
    return &AccountService{repo: repo}
}

func (s *AccountService) Create(ctx context.Context, email string) (domain.Account, error) {
    _, err := s.repo.GetByEmail(ctx, email)
    if err == nil {
        return domain.Account{}, domain.ErrEmailAlreadyTaken
    }
    if !errors.Is(err, domain.ErrAccountNotFound) {
        return domain.Account{}, fmt.Errorf("check email: %w", err)
    }

    acc := domain.Account{
        ID:     domain.AccountID(newID()),
        Email:  email,
        Status: domain.AccountStatusActive,
    }
    if err := s.repo.Create(ctx, acc); err != nil {
        return domain.Account{}, fmt.Errorf("create account: %w", err)
    }
    return acc, nil
}
```

---

## 5. Configuration

Load all config from environment variables at startup. Fail fast on missing required values.

```go
// config/config.go
package config

import (
    "fmt"
    "os"
    "strconv"
    "time"
)

type Config struct {
    App      AppConfig
    Database DatabaseConfig
    Auth     AuthConfig
    Redis    RedisConfig
    SMTP     SMTPConfig
    Otel     OtelConfig
}

type AppConfig struct {
    Env        string        // local | staging | production
    Port       int
    Name       string
    Version    string
    RequestTimeout time.Duration
}

type DatabaseConfig struct {
    URL             string
    MaxOpenConns    int
    MaxIdleConns    int
    ConnMaxLifetime time.Duration
}

type AuthConfig struct {
    JWTSecret          string
    AccessTokenTTL     time.Duration
    RefreshTokenTTL    time.Duration
}

func Load() (Config, error) {
    port, err := strconv.Atoi(getEnv("PORT", "8080"))
    if err != nil {
        return Config{}, fmt.Errorf("invalid PORT: %w", err)
    }

    cfg := Config{
        App: AppConfig{
            Env:     getEnv("APP_ENV", "local"),
            Port:    port,
            Name:    getEnv("APP_NAME", "my-service"),
            Version: getEnv("APP_VERSION", "dev"),
        },
        Database: DatabaseConfig{
            URL:             requireEnv("DATABASE_URL"),
            MaxOpenConns:    25,
            MaxIdleConns:    5,
            ConnMaxLifetime: 5 * time.Minute,
        },
        Auth: AuthConfig{
            JWTSecret:       requireEnv("JWT_SECRET"),
            AccessTokenTTL:  15 * time.Minute,
            RefreshTokenTTL: 7 * 24 * time.Hour,
        },
    }
    return cfg, nil
}

func requireEnv(key string) string {
    v := os.Getenv(key)
    if v == "" {
        panic(fmt.Sprintf("required env var %q is not set", key))
    }
    return v
}

func getEnv(key, fallback string) string {
    if v := os.Getenv(key); v != "" {
        return v
    }
    return fallback
}
```

### .env.example — always up to date

```bash
# Application
APP_ENV=local
APP_NAME=my-service
APP_VERSION=dev
PORT=8080

# Database
DATABASE_URL=postgres://user:password@localhost:5432/mydb?sslmode=disable

# Auth
JWT_SECRET=change-me-in-production

# Redis
REDIS_URL=redis://localhost:6379

# SMTP
SMTP_HOST=localhost
SMTP_PORT=1025
SMTP_FROM=noreply@example.com

# Observability
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
```

---

## 6. HTTP Layer

### Router — chi (recommended in 2026)

```go
// internal/handler/server.go
package handler

import (
    "context"
    "fmt"
    "net/http"
    "time"

    "github.com/go-chi/chi/v5"
    chimiddleware "github.com/go-chi/chi/v5/middleware"
    "github.com/org/my-service/config"
    "github.com/org/my-service/internal/service"
)

type Server struct {
    srv *http.Server
}

func NewServer(cfg config.Config, accountSvc *service.AccountService) *Server {
    r := chi.NewRouter()

    // Global middleware (order matters)
    r.Use(chimiddleware.RequestID)
    r.Use(chimiddleware.RealIP)
    r.Use(RequestLogger)
    r.Use(Recoverer)
    r.Use(chimiddleware.Timeout(30 * time.Second))

    accountHandler := NewAccountHandler(accountSvc)

    r.Get("/health", HealthHandler)

    r.Route("/v1", func(r chi.Router) {
        r.Use(AuthMiddleware(cfg.Auth))

        r.Route("/accounts", func(r chi.Router) {
            r.Post("/", accountHandler.Create)
            r.Get("/{id}", accountHandler.GetByID)
            r.Put("/{id}", accountHandler.Update)
            r.Delete("/{id}", accountHandler.Delete)
        })
    })

    return &Server{
        srv: &http.Server{
            Addr:         fmt.Sprintf(":%d", cfg.App.Port),
            Handler:      r,
            ReadTimeout:  5 * time.Second,
            WriteTimeout: 10 * time.Second,
            IdleTimeout:  120 * time.Second,
        },
    }
}

func (s *Server) Start(ctx context.Context) error {
    errCh := make(chan error, 1)
    go func() {
        if err := s.srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            errCh <- err
        }
    }()

    select {
    case err := <-errCh:
        return fmt.Errorf("server error: %w", err)
    case <-ctx.Done():
        shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
        defer cancel()
        return s.srv.Shutdown(shutdownCtx)
    }
}
```

### Handler — thin, no logic

```go
// internal/handler/account.go
package handler

import (
    "net/http"

    "github.com/go-chi/chi/v5"
    "github.com/org/my-service/internal/domain"
    "github.com/org/my-service/internal/service"
    "github.com/org/my-service/pkg/apierr"
    "github.com/org/my-service/pkg/render"
)

type AccountHandler struct {
    svc *service.AccountService
}

func NewAccountHandler(svc *service.AccountService) *AccountHandler {
    return &AccountHandler{svc: svc}
}

type createAccountRequest struct {
    Email string `json:"email" validate:"required,email"`
}

func (h *AccountHandler) Create(w http.ResponseWriter, r *http.Request) {
    var req createAccountRequest
    if err := render.DecodeJSON(r, &req); err != nil {
        render.Error(w, apierr.BadRequest("invalid request body"))
        return
    }

    acc, err := h.svc.Create(r.Context(), req.Email)
    if err != nil {
        render.Error(w, mapDomainError(err))
        return
    }

    render.JSON(w, http.StatusCreated, toAccountResponse(acc))
}

func mapDomainError(err error) apierr.APIError {
    switch {
    case errors.Is(err, domain.ErrAccountNotFound):
        return apierr.NotFound("account not found")
    case errors.Is(err, domain.ErrEmailAlreadyTaken):
        return apierr.Conflict("email already taken")
    case errors.Is(err, domain.ErrAccountSuspended):
        return apierr.UnprocessableEntity("account is suspended")
    default:
        return apierr.Internal()
    }
}
```

### Response shape (always consistent)

```json
// Success
{ "data": { ... } }

// List
{ "data": [...], "meta": { "next_cursor": "...", "total": 100 } }

// Error
{ "error": { "code": "EMAIL_TAKEN", "message": "email already taken", "details": {} } }
```

---

## 7. gRPC Layer

```go
// internal/grpc/account_server.go
package grpc

import (
    "context"

    "google.golang.org/grpc/codes"
    "google.golang.org/grpc/status"
    pb "github.com/org/my-service/api/proto/v1"
    "github.com/org/my-service/internal/domain"
    "github.com/org/my-service/internal/service"
)

type AccountServer struct {
    pb.UnimplementedAccountServiceServer
    svc *service.AccountService
}

func (s *AccountServer) GetAccount(ctx context.Context, req *pb.GetAccountRequest) (*pb.Account, error) {
    acc, err := s.svc.GetByID(ctx, domain.AccountID(req.Id))
    if err != nil {
        return nil, mapToGRPCError(err)
    }
    return toProtoAccount(acc), nil
}

func mapToGRPCError(err error) error {
    switch {
    case errors.Is(err, domain.ErrAccountNotFound):
        return status.Error(codes.NotFound, err.Error())
    case errors.Is(err, domain.ErrEmailAlreadyTaken):
        return status.Error(codes.AlreadyExists, err.Error())
    default:
        return status.Error(codes.Internal, "internal server error")
    }
}
```

### Protobuf conventions

- One `.proto` file per domain entity.
- Use `buf` for linting and breaking change detection.
- Never commit generated `.pb.go` files — generate in CI.
- Enable `buf lint` in CI: `buf lint && buf breaking --against '.git#branch=main'`.

---

## 8. Database Layer

### Connection (pgx v5)

```go
// internal/repository/postgres/db.go
package postgres

import (
    "context"
    "fmt"

    "github.com/jackc/pgx/v5/pgxpool"
    "github.com/org/my-service/config"
)

func Connect(ctx context.Context, cfg config.DatabaseConfig) (*pgxpool.Pool, error) {
    poolCfg, err := pgxpool.ParseConfig(cfg.URL)
    if err != nil {
        return nil, fmt.Errorf("parse db config: %w", err)
    }

    poolCfg.MaxConns = int32(cfg.MaxOpenConns)
    poolCfg.MinConns = int32(cfg.MaxIdleConns)
    poolCfg.MaxConnLifetime = cfg.ConnMaxLifetime

    pool, err := pgxpool.NewWithConfig(ctx, poolCfg)
    if err != nil {
        return nil, fmt.Errorf("create pool: %w", err)
    }

    if err := pool.Ping(ctx); err != nil {
        return nil, fmt.Errorf("ping db: %w", err)
    }

    return pool, nil
}
```

### Repository implementation

```go
// internal/repository/postgres/account.go
package postgres

import (
    "context"
    "errors"
    "fmt"

    "github.com/jackc/pgx/v5"
    "github.com/jackc/pgx/v5/pgxpool"
    "github.com/org/my-service/internal/domain"
)

type AccountRepository struct {
    db *pgxpool.Pool
}

func NewAccountRepository(db *pgxpool.Pool) *AccountRepository {
    return &AccountRepository{db: db}
}

func (r *AccountRepository) GetByID(ctx context.Context, id domain.AccountID) (domain.Account, error) {
    const q = `
        SELECT id, email, status, created_at, updated_at
        FROM accounts
        WHERE id = $1 AND deleted_at IS NULL`

    var acc domain.Account
    err := r.db.QueryRow(ctx, q, id).Scan(
        &acc.ID, &acc.Email, &acc.Status, &acc.CreatedAt, &acc.UpdatedAt,
    )
    if err != nil {
        if errors.Is(err, pgx.ErrNoRows) {
            return domain.Account{}, domain.ErrAccountNotFound
        }
        return domain.Account{}, fmt.Errorf("query account: %w", err)
    }
    return acc, nil
}
```

### Migrations (goose)

```sql
-- migrations/001_init.up.sql
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE accounts (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email       TEXT NOT NULL UNIQUE,
    status      TEXT NOT NULL DEFAULT 'active',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ
);

CREATE INDEX idx_accounts_email ON accounts(email) WHERE deleted_at IS NULL;
```

```sql
-- migrations/001_init.down.sql
DROP TABLE IF EXISTS accounts;
```

### Migration rules

- Name files `NNN_short_description.{up,down}.sql`.
- Never edit a migration once merged to `main` — add a new one.
- Always write a `down` migration.
- Use `goose` or `golang-migrate` — pick one per project, never mix.
- Run migrations at startup only in dev/staging; use a separate `migrate` command in production.

---

## 9. Domain / Business Logic Layer

### Aggregate rules

- Aggregates own their invariants — enforce them in domain methods, not in handlers.
- Never expose raw struct fields from aggregates if they can be set to invalid state.
- Value objects (e.g. `Email`, `Money`, `PhoneNumber`) validate on construction.

```go
type Email struct{ value string }

func NewEmail(s string) (Email, error) {
    if !emailRegex.MatchString(s) {
        return Email{}, errors.New("invalid email format")
    }
    return Email{value: s}, nil
}

func (e Email) String() string { return e.value }
```

### Events

Publish domain events for state transitions — never trigger side-effects directly from services.

```go
type AccountCreated struct {
    AccountID domain.AccountID
    Email     string
    OccurredAt time.Time
}
```

---

## 10. Error Handling

### Rules

- Always wrap errors with context: `fmt.Errorf("create account: %w", err)`.
- Never use `panic` except for truly unrecoverable state (e.g., nil config at startup).
- Never log and return an error — do one or the other (prefer return; let the top level log).
- Do not use sentinel `nil` for "not found" — return a typed domain error.

### Typed API errors (pkg/apierr)

```go
package apierr

import "net/http"

type APIError struct {
    Status  int    `json:"-"`
    Code    string `json:"code"`
    Message string `json:"message"`
}

func (e APIError) Error() string { return e.Message }

func NotFound(msg string) APIError {
    return APIError{Status: http.StatusNotFound, Code: "NOT_FOUND", Message: msg}
}

func BadRequest(msg string) APIError {
    return APIError{Status: http.StatusBadRequest, Code: "BAD_REQUEST", Message: msg}
}

func Conflict(msg string) APIError {
    return APIError{Status: http.StatusConflict, Code: "CONFLICT", Message: msg}
}

func Internal() APIError {
    return APIError{Status: http.StatusInternalServerError, Code: "INTERNAL", Message: "internal server error"}
}
```

---

## 11. Logging and Observability

### Logging — log/slog (stdlib, Go 1.21+)

```go
import "log/slog"

// At startup — configure once
logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
    Level: slog.LevelInfo,
}))
slog.SetDefault(logger)

// Usage
slog.InfoContext(ctx, "account created", "account_id", acc.ID, "email", acc.Email)
slog.ErrorContext(ctx, "failed to send email", "err", err, "account_id", acc.ID)
```

- Always use `slog.XxxContext` to propagate trace IDs.
- Log at `INFO` for normal operations, `WARN` for recoverable issues, `ERROR` for failures.
- Never log sensitive data (passwords, tokens, PII in prod).
- JSON format in production, text format in local dev.

### Tracing — OpenTelemetry

```go
import (
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/trace"
)

var tracer = otel.Tracer("account-service")

func (s *AccountService) Create(ctx context.Context, email string) (domain.Account, error) {
    ctx, span := tracer.Start(ctx, "AccountService.Create")
    defer span.End()

    // ... business logic
}
```

- Instrument every service method and repository call.
- Export to OTLP endpoint (Grafana Tempo, Jaeger, or Datadog).
- Use `otelchi` middleware to auto-instrument HTTP handlers.

### Metrics — Prometheus

```go
import "github.com/prometheus/client_golang/prometheus"

var httpRequestDuration = prometheus.NewHistogramVec(
    prometheus.HistogramOpts{
        Name:    "http_request_duration_seconds",
        Help:    "HTTP request duration in seconds",
        Buckets: prometheus.DefBuckets,
    },
    []string{"method", "path", "status"},
)
```

- Expose `/metrics` on a separate internal port (e.g. 9090).
- Do not expose metrics on the public port.
- Key metrics: request duration, error rate, DB pool stats, queue lag.

---

## 12. Testing Strategy

### Test types

| Type        | Location                  | What it tests           | DB? | External? |
| ----------- | ------------------------- | ----------------------- | --- | --------- |
| Unit        | `*_test.go` beside source | Pure logic, mocked deps | No  | No        |
| Integration | `*_integration_test.go`   | Real DB, real adapters  | Yes | No        |
| E2E         | `tests/e2e/`              | Full HTTP flow          | Yes | Minimal   |

### Unit tests

```go
// internal/service/account_test.go
func TestAccountService_Create_EmailAlreadyTaken(t *testing.T) {
    repo := &mocks.AccountRepository{}
    repo.On("GetByEmail", mock.Anything, "taken@example.com").Return(domain.Account{}, nil)

    svc := service.NewAccountService(repo)
    _, err := svc.Create(context.Background(), "taken@example.com")

    assert.ErrorIs(t, err, domain.ErrEmailAlreadyTaken)
    repo.AssertExpectations(t)
}
```

### Integration tests

```go
//go:build integration

func TestAccountRepository_CreateAndGet(t *testing.T) {
    db := testdb.New(t)  // spins up a real test DB, cleaned up on t.Cleanup
    repo := postgres.NewAccountRepository(db)

    acc := domain.Account{ID: "test-id", Email: "a@b.com", Status: domain.AccountStatusActive}
    err := repo.Create(context.Background(), acc)
    require.NoError(t, err)

    got, err := repo.GetByID(context.Background(), "test-id")
    require.NoError(t, err)
    assert.Equal(t, acc.Email, got.Email)
}
```

### Test DB helper

Use `testcontainers-go` for hermetic integration tests:

```go
// internal/testutil/testdb/db.go
package testdb

import (
    "context"
    "testing"

    "github.com/testcontainers/testcontainers-go/modules/postgres"
)

func New(t *testing.T) *pgxpool.Pool {
    t.Helper()
    ctx := context.Background()

    container, err := postgres.Run(ctx, "postgres:16-alpine",
        postgres.WithDatabase("testdb"),
        postgres.WithUsername("test"),
        postgres.WithPassword("test"),
        testcontainers.WithWaitStrategy(wait.ForListeningPort("5432/tcp")),
    )
    require.NoError(t, err)
    t.Cleanup(func() { container.Terminate(ctx) })

    // run migrations against test DB...
    return connectPool(ctx, t, container.ConnectionString(ctx))
}
```

### Mocks — mockery v2

```bash
# .mockery.yaml
with-expecter: true
packages:
  github.com/org/my-service/internal/domain:
    interfaces:
      AccountRepository:
```

Run `make gen` to regenerate. Never hand-edit generated mocks.

---

## 13. Background Workers and Jobs

```go
// internal/worker/email_worker.go
package worker

import (
    "context"
    "log/slog"
    "time"
)

type EmailWorker struct {
    mailer Mailer
    queue  Queue
}

func (w *EmailWorker) Run(ctx context.Context) error {
    for {
        select {
        case <-ctx.Done():
            return nil
        default:
            if err := w.processNext(ctx); err != nil {
                slog.ErrorContext(ctx, "email worker error", "err", err)
                time.Sleep(5 * time.Second) // backoff
            }
        }
    }
}
```

- Workers receive a `context.Context` — shut down cleanly when ctx is cancelled.
- Use `golang.org/x/sync/errgroup` to run multiple workers:

```go
g, ctx := errgroup.WithContext(ctx)
g.Go(func() error { return emailWorker.Run(ctx) })
g.Go(func() error { return invoiceWorker.Run(ctx) })
return g.Wait()
```

---

## 14. Event-Driven Architecture

### Event bus abstraction

```go
// internal/event/publisher.go
package event

import "context"

type Publisher interface {
    Publish(ctx context.Context, topic string, payload any) error
}

type Subscriber interface {
    Subscribe(ctx context.Context, topic string, handler HandlerFunc) error
}

type HandlerFunc func(ctx context.Context, msg Message) error
```

- Supported backends: NATS JetStream, Kafka (sarama or franz-go), Google Pub/Sub.
- Topic names are constants in `internal/event/topics.go`.
- Events are versioned: `account.created.v1`.
- Events are idempotent — consumers must handle duplicates (use event ID as idempotency key).

---

## 15. Authentication and Authorization

### JWT middleware

```go
func AuthMiddleware(cfg config.AuthConfig) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            token := extractBearerToken(r)
            if token == "" {
                render.Error(w, apierr.Unauthorized("missing token"))
                return
            }

            claims, err := jwt.Parse(token, cfg.JWTSecret)
            if err != nil {
                render.Error(w, apierr.Unauthorized("invalid token"))
                return
            }

            ctx := context.WithValue(r.Context(), ctxKeyUser, claims)
            next.ServeHTTP(w, r.WithContext(ctx))
        })
    }
}
```

### RBAC

- Define roles as constants in `internal/domain/role.go`.
- Authorization checks belong in the service layer, not handlers.
- Use a dedicated `Authorizer` interface so authorization logic is testable.

---

## 16. Caching

```go
// internal/cache/account_cache.go
package cache

import (
    "context"
    "encoding/json"
    "fmt"
    "time"

    "github.com/redis/go-redis/v9"
    "github.com/org/my-service/internal/domain"
)

type AccountCache struct {
    client *redis.Client
    ttl    time.Duration
}

func (c *AccountCache) Get(ctx context.Context, id domain.AccountID) (domain.Account, error) {
    data, err := c.client.Get(ctx, c.key(id)).Bytes()
    if err != nil {
        if errors.Is(err, redis.Nil) {
            return domain.Account{}, domain.ErrAccountNotFound
        }
        return domain.Account{}, fmt.Errorf("cache get: %w", err)
    }

    var acc domain.Account
    if err := json.Unmarshal(data, &acc); err != nil {
        return domain.Account{}, fmt.Errorf("cache unmarshal: %w", err)
    }
    return acc, nil
}

func (c *AccountCache) key(id domain.AccountID) string {
    return fmt.Sprintf("account:%s", id)
}
```

- Cache-aside pattern: read from cache → on miss read from DB → populate cache.
- Invalidate on write/delete — never rely on TTL alone for correctness.
- Use cache only where latency matters (hot read paths).

---

## 17. Graceful Shutdown

```go
func (s *Server) Start(ctx context.Context) error {
    errCh := make(chan error, 1)

    go func() {
        slog.Info("server listening", "addr", s.srv.Addr)
        if err := s.srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
            errCh <- err
        }
    }()

    select {
    case err := <-errCh:
        return err
    case <-ctx.Done():
        slog.Info("shutting down server")
        shutdownCtx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
        defer cancel()
        return s.srv.Shutdown(shutdownCtx)
    }
}
```

Shutdown order (always):

1. Stop accepting new connections (HTTP `Shutdown`)
2. Drain in-flight requests (respect timeout)
3. Stop background workers (cancel errgroup context)
4. Close DB pool
5. Flush telemetry (traces, logs)

---

## 18. Docker and Deployment

### Multi-stage Dockerfile

```dockerfile
# docker/Dockerfile
FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /bin/server ./cmd/server

FROM gcr.io/distroless/static-debian12 AS final
COPY --from=builder /bin/server /server
EXPOSE 8080
ENTRYPOINT ["/server"]
```

### docker-compose.yml (dev)

```yaml
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: mydb
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    ports: ["5432:5432"]
    volumes: [pgdata:/var/lib/postgresql/data]

  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]

  mailpit:
    image: axllent/mailpit
    ports: ["1025:1025", "8025:8025"] # SMTP + web UI

  otel-collector:
    image: otel/opentelemetry-collector-contrib:latest
    ports: ["4318:4318"]

volumes:
  pgdata:
```

---

## 19. CI/CD Pipeline

### GitHub Actions — ci.yml

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

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
        ports: ["5432:5432"]

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-go@v5
        with:
          go-version-file: go.mod
          cache: true

      - name: Verify go.mod tidy
        run: |
          go mod tidy
          git diff --exit-code go.mod go.sum

      - name: Lint
        uses: golangci/golangci-lint-action@v6
        with:
          version: latest

      - name: Unit tests
        run: go test ./... -race -count=1

      - name: Integration tests
        run: go test ./... -tags=integration -race -count=1
        env:
          DATABASE_URL: postgres://test:test@localhost:5432/testdb?sslmode=disable

      - name: Build
        run: go build ./cmd/...

      - name: govulncheck
        run: go run golang.org/x/vuln/cmd/govulncheck@latest ./...
```

### Release pipeline

- Tag `vX.Y.Z` on `main` triggers image build and push.
- Use `goreleaser` for binary releases.
- Image scanning with `trivy` before pushing.

---

## 20. Security Checklist

- [ ] All secrets from env vars — never committed.
- [ ] Parameterized queries everywhere — no string interpolation in SQL.
- [ ] Input validated at the handler boundary (`pkg/validator`).
- [ ] Auth middleware applied to every non-public route.
- [ ] Sensitive data (passwords, tokens) never logged.
- [ ] Passwords hashed with `bcrypt` (cost ≥ 12) or `argon2id`.
- [ ] Rate limiting at reverse proxy or API gateway layer.
- [ ] CORS headers configured tightly (not `*` in production).
- [ ] TLS termination at load balancer; internal traffic over private network.
- [ ] `govulncheck` and `trivy` in CI.
- [ ] DB user has minimum required permissions (no `SUPERUSER`).
- [ ] Timeouts on all outbound HTTP clients — never `http.DefaultClient`.
- [ ] Docker image runs as non-root user.
- [ ] Secrets in Kubernetes via `Secret` objects, not `ConfigMap`.

---

## 21. Common Toolchain

| Tool                | Purpose                       | Install                                                                      |
| ------------------- | ----------------------------- | ---------------------------------------------------------------------------- |
| `golangci-lint`     | Lint aggregator               | `go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest`      |
| `goose`             | DB migrations                 | `go install github.com/pressly/goose/v3/cmd/goose@latest`                    |
| `mockery`           | Interface mock generation     | `go install github.com/vektra/mockery/v2@latest`                             |
| `buf`               | Protobuf lint + codegen       | `go install github.com/bufbuild/buf/cmd/buf@latest`                          |
| `oapi-codegen`      | OpenAPI → Go types + server   | `go install github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen@latest` |
| `goreleaser`        | Binary release automation     | `go install github.com/goreleaser/goreleaser/v2@latest`                      |
| `govulncheck`       | Vulnerability scanner         | `go install golang.org/x/vuln/cmd/govulncheck@latest`                        |
| `testcontainers-go` | Hermetic integration test DBs | (library — add to go.mod)                                                    |
| `air`               | Live reload in dev            | `go install github.com/air-verse/air@latest`                                 |

### Recommended .golangci.yml linters

```yaml
linters:
  enable:
    - errcheck
    - govet
    - staticcheck
    - gosec
    - gocyclo
    - dupl
    - misspell
    - unconvert
    - unparam
    - exhaustruct
    - wrapcheck
    - contextcheck
    - noctx
    - rowserrcheck
    - sqlclosecheck
    - bodyclose

linters-settings:
  gocyclo:
    min-complexity: 15
  gosec:
    excludes: [G401, G501] # allow MD5/SHA1 for non-security use

issues:
  exclude-rules:
    - path: "_test\\.go"
      linters: [exhaustruct, dupl]
```

---

## Makefile reference

```makefile
.PHONY: run build test test-integration lint gen migrate migrate-down infra-up infra-down

run:
	air -c .air.toml

build:
	go build -o bin/server ./cmd/server

test:
	go test ./... -race -count=1

test-integration:
	go test ./... -tags=integration -race -count=1

lint:
	golangci-lint run ./...

gen:
	go generate ./...

migrate:
	goose -dir migrations postgres "$(DATABASE_URL)" up

migrate-down:
	goose -dir migrations postgres "$(DATABASE_URL)" down

infra-up:
	docker compose -f docker/docker-compose.yml up -d

infra-down:
	docker compose -f docker/docker-compose.yml down

tidy:
	go mod tidy
```
