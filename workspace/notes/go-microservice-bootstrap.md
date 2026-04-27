# The Ultimate Golang Microservice Bootstrap Guide to Production-Ready Setup

> A pragmatic, opinionated guide to going from `go mod init` to a service you can actually ship.

---

## Table of Contents

- [The Ultimate Golang Microservice Bootstrap Guide to Production-Ready Setup](#the-ultimate-golang-microservice-bootstrap-guide-to-production-ready-setup)
  - [Table of Contents](#table-of-contents)
  - [1. Project Structure](#1-project-structure)
  - [2. Configuration Management](#2-configuration-management)
  - [3. Dependency Injection](#3-dependency-injection)
  - [4. HTTP Server \& Routing](#4-http-server--routing)
  - [5. gRPC Server](#5-grpc-server)
  - [6. Database Layer](#6-database-layer)
  - [7. Migrations](#7-migrations)
  - [8. Logging](#8-logging)
  - [9. Observability: Metrics, Tracing, Profiling](#9-observability-metrics-tracing-profiling)
  - [10. Error Handling](#10-error-handling)
  - [11. Middleware](#11-middleware)
    - [Request ID](#request-id)
    - [Rate Limiting](#rate-limiting)
    - [Timeout](#timeout)
  - [12. Authentication \& Authorization](#12-authentication--authorization)
    - [JWT Validation Middleware](#jwt-validation-middleware)
    - [RBAC](#rbac)
  - [13. Message Queue / Event Streaming](#13-message-queue--event-streaming)
  - [14. Caching](#14-caching)
  - [15. Graceful Shutdown](#15-graceful-shutdown)
  - [16. Health Checks \& Readiness Probes](#16-health-checks--readiness-probes)
  - [17. Testing Strategy](#17-testing-strategy)
    - [Unit Tests](#unit-tests)
    - [Integration Tests](#integration-tests)
    - [HTTP Tests](#http-tests)
  - [18. Dockerfile \& Container Hardening](#18-dockerfile--container-hardening)
  - [19. CI/CD Pipeline (GitHub Actions)](#19-cicd-pipeline-github-actions)
  - [20. Kubernetes Manifests](#20-kubernetes-manifests)
  - [21. Security Checklist](#21-security-checklist)
  - [22. Production Checklist](#22-production-checklist)
  - [Key Dependencies Reference](#key-dependencies-reference)
  - [Makefile](#makefile)

---

## 1. Project Structure

Follow the battle-tested layout. Do **not** use `pkg/` for internal code — just `internal/`.

```
myservice/
├── cmd/
│   └── server/
│       └── main.go           # entry point — thin as possible
├── internal/
│   ├── config/               # config loading & validation
│   ├── domain/               # pure business entities & interfaces
│   │   ├── user.go
│   │   └── user_repository.go
│   ├── usecase/              # application logic — orchestrates domain
│   │   └── user_usecase.go
│   ├── repository/           # concrete DB/cache implementations
│   │   └── user_postgres.go
│   ├── handler/              # HTTP or gRPC handlers — thin, call usecases
│   │   └── user_handler.go
│   ├── middleware/
│   ├── server/               # HTTP/gRPC server wiring
│   └── telemetry/            # OTEL setup
├── api/
│   └── proto/                # .proto files + generated code
├── migrations/               # SQL migration files
├── deploy/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── k8s/
├── scripts/
├── .github/
│   └── workflows/
├── go.mod
├── go.sum
├── Makefile
└── .golangci.yml
```

**Why this layout?**

- `cmd/` keeps `main.go` tiny — it only wires things together.
- `internal/` prevents accidental imports by other modules.
- Domain → Usecase → Repository direction enforces dependency inversion; nothing in `domain/` imports `repository/`.

---

## 2. Configuration Management

Use **`viper`** + **`envconfig`** or just **`cleanenv`**. Never hardcode values. Always validate at startup.

```go
// internal/config/config.go
package config

import (
    "time"
    "github.com/ilyakaznacheev/cleanenv"
)

type Config struct {
    App      AppConfig
    HTTP     HTTPConfig
    GRPC     GRPCConfig
    Database DatabaseConfig
    Redis    RedisConfig
    OTEL     OTELConfig
    Auth     AuthConfig
}

type AppConfig struct {
    Name        string `env:"APP_NAME"        env-default:"myservice"`
    Env         string `env:"APP_ENV"         env-default:"development"`
    Version     string `env:"APP_VERSION"     env-default:"dev"`
    LogLevel    string `env:"LOG_LEVEL"       env-default:"info"`
}

type HTTPConfig struct {
    Port            int           `env:"HTTP_PORT"             env-default:"8080"`
    ReadTimeout     time.Duration `env:"HTTP_READ_TIMEOUT"     env-default:"10s"`
    WriteTimeout    time.Duration `env:"HTTP_WRITE_TIMEOUT"    env-default:"10s"`
    IdleTimeout     time.Duration `env:"HTTP_IDLE_TIMEOUT"     env-default:"60s"`
    ShutdownTimeout time.Duration `env:"HTTP_SHUTDOWN_TIMEOUT" env-default:"15s"`
}

type GRPCConfig struct {
    Port int `env:"GRPC_PORT" env-default:"9090"`
}

type DatabaseConfig struct {
    DSN             string        `env:"DB_DSN"              env-required:"true"`
    MaxOpenConns    int           `env:"DB_MAX_OPEN_CONNS"   env-default:"25"`
    MaxIdleConns    int           `env:"DB_MAX_IDLE_CONNS"   env-default:"10"`
    ConnMaxLifetime time.Duration `env:"DB_CONN_MAX_LIFETIME" env-default:"5m"`
}

type RedisConfig struct {
    Addr     string `env:"REDIS_ADDR"     env-default:"localhost:6379"`
    Password string `env:"REDIS_PASSWORD" env-default:""`
    DB       int    `env:"REDIS_DB"       env-default:"0"`
}

type OTELConfig struct {
    Endpoint       string  `env:"OTEL_EXPORTER_OTLP_ENDPOINT" env-default:""`
    ServiceName    string  `env:"OTEL_SERVICE_NAME"            env-default:"myservice"`
    SamplingRatio  float64 `env:"OTEL_SAMPLING_RATIO"          env-default:"1.0"`
}

type AuthConfig struct {
    JWTSecret      string        `env:"JWT_SECRET"       env-required:"true"`
    TokenTTL       time.Duration `env:"JWT_TOKEN_TTL"    env-default:"24h"`
}

func Load() (*Config, error) {
    cfg := &Config{}
    if err := cleanenv.ReadEnv(cfg); err != nil {
        return nil, err
    }
    return cfg, nil
}
```

**Rules:**

- `env-required:"true"` causes a startup crash with a clear message — good.
- Keep a `.env.example` file committed; never commit `.env`.
- In Kubernetes, inject secrets via `envFrom: secretRef`, not config maps.

---

## 3. Dependency Injection

Avoid DI frameworks (wire, dig) unless the graph is huge. Manual DI in `main.go` is the clearest approach.

```go
// cmd/server/main.go
package main

import (
    "context"
    "log/slog"
    "os"

    "myservice/internal/config"
    "myservice/internal/repository"
    "myservice/internal/server"
    "myservice/internal/telemetry"
    "myservice/internal/usecase"
)

func main() {
    cfg, err := config.Load()
    if err != nil {
        slog.Error("failed to load config", "error", err)
        os.Exit(1)
    }

    // Telemetry first — so everything below is instrumented
    shutdown, err := telemetry.Setup(context.Background(), cfg.OTEL)
    if err != nil {
        slog.Error("failed to setup telemetry", "error", err)
        os.Exit(1)
    }
    defer shutdown(context.Background())

    // Data layer
    db, err := repository.NewPostgresDB(cfg.Database)
    if err != nil {
        slog.Error("failed to connect to database", "error", err)
        os.Exit(1)
    }
    defer db.Close()

    rdb := repository.NewRedis(cfg.Redis)
    defer rdb.Close()

    // Repositories
    userRepo := repository.NewUserRepository(db)

    // Usecases
    userUC := usecase.NewUserUsecase(userRepo, rdb)

    // Servers
    srv := server.New(cfg, userUC)
    srv.Run()
}
```

If the graph grows, use **`google/wire`** — it generates code, no reflection at runtime.

---

## 4. HTTP Server & Routing

Use **`chi`** or **`echo`**. `net/http` is fine too but lacks grouping/middleware helpers. Example with `chi`:

```go
// internal/server/http.go
package server

import (
    "fmt"
    "net/http"

    "github.com/go-chi/chi/v5"
    "github.com/go-chi/chi/v5/middleware"
    "myservice/internal/config"
    "myservice/internal/handler"
    mw "myservice/internal/middleware"
)

func NewHTTPServer(cfg *config.Config, userHandler *handler.UserHandler) *http.Server {
    r := chi.NewRouter()

    // Global middleware
    r.Use(middleware.RequestID)
    r.Use(middleware.RealIP)
    r.Use(mw.Logger)           // structured slog logging
    r.Use(mw.Recoverer)        // panic → 500 + log
    r.Use(mw.OTEL)             // trace + span per request
    r.Use(middleware.Compress(5))

    // Health (no auth)
    r.Get("/healthz", handler.Healthz)
    r.Get("/readyz",  handler.Readyz)

    // API v1
    r.Route("/api/v1", func(r chi.Router) {
        r.Use(mw.Auth(cfg.Auth))

        r.Route("/users", func(r chi.Router) {
            r.Get("/",        userHandler.List)
            r.Post("/",       userHandler.Create)
            r.Get("/{id}",    userHandler.Get)
            r.Put("/{id}",    userHandler.Update)
            r.Delete("/{id}", userHandler.Delete)
        })
    })

    return &http.Server{
        Addr:         fmt.Sprintf(":%d", cfg.HTTP.Port),
        Handler:      r,
        ReadTimeout:  cfg.HTTP.ReadTimeout,
        WriteTimeout: cfg.HTTP.WriteTimeout,
        IdleTimeout:  cfg.HTTP.IdleTimeout,
    }
}
```

**Handler pattern — keep it thin:**

```go
// internal/handler/user_handler.go
func (h *UserHandler) Create(w http.ResponseWriter, r *http.Request) {
    var req CreateUserRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        respondError(w, http.StatusBadRequest, "invalid request body")
        return
    }
    if err := validate(req); err != nil {
        respondError(w, http.StatusUnprocessableEntity, err.Error())
        return
    }

    user, err := h.userUC.Create(r.Context(), req.toDomain())
    if err != nil {
        handleUsecaseError(w, err)
        return
    }

    respondJSON(w, http.StatusCreated, toUserResponse(user))
}
```

---

## 5. gRPC Server

```go
// internal/server/grpc.go
package server

import (
    "fmt"
    "net"

    "google.golang.org/grpc"
    "google.golang.org/grpc/health"
    healthpb "google.golang.org/grpc/health/grpc_health_v1"
    "google.golang.org/grpc/reflection"
    "go.opentelemetry.io/contrib/instrumentation/google.golang.org/grpc/otelgrpc"

    pb "myservice/api/proto/gen"
    "myservice/internal/config"
)

func NewGRPCServer(cfg *config.Config, userSvc pb.UserServiceServer) *grpc.Server {
    srv := grpc.NewServer(
        grpc.StatsHandler(otelgrpc.NewServerHandler()),
        grpc.ChainUnaryInterceptor(
            recoveryInterceptor,
            authInterceptor(cfg.Auth),
        ),
    )

    pb.RegisterUserServiceServer(srv, userSvc)

    // Standard health protocol — Kubernetes can probe this
    healthSrv := health.NewServer()
    healthpb.RegisterHealthServer(srv, healthSrv)
    healthSrv.SetServingStatus("", healthpb.HealthCheckResponse_SERVING)

    // Only enable reflection in non-production
    if cfg.App.Env != "production" {
        reflection.Register(srv)
    }

    return srv
}

func ListenGRPC(cfg *config.Config, srv *grpc.Server) error {
    lis, err := net.Listen("tcp", fmt.Sprintf(":%d", cfg.GRPC.Port))
    if err != nil {
        return err
    }
    return srv.Serve(lis)
}
```

---

## 6. Database Layer

Use **`pgx/v5`** directly (not GORM) for performance-critical services, or **`sqlc`** for type-safe generated queries.

```go
// internal/repository/postgres.go
package repository

import (
    "context"
    "time"

    "github.com/jackc/pgx/v5/pgxpool"
    "myservice/internal/config"
)

func NewPostgresDB(cfg config.DatabaseConfig) (*pgxpool.Pool, error) {
    poolCfg, err := pgxpool.ParseConfig(cfg.DSN)
    if err != nil {
        return nil, err
    }

    poolCfg.MaxConns            = int32(cfg.MaxOpenConns)
    poolCfg.MinConns            = int32(cfg.MaxIdleConns)
    poolCfg.MaxConnLifetime     = cfg.ConnMaxLifetime
    poolCfg.MaxConnIdleTime     = 5 * time.Minute
    poolCfg.HealthCheckPeriod   = 1 * time.Minute

    ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()

    pool, err := pgxpool.NewWithConfig(ctx, poolCfg)
    if err != nil {
        return nil, err
    }

    if err := pool.Ping(ctx); err != nil {
        return nil, err
    }

    return pool, nil
}
```

**Repository implementation:**

```go
// internal/repository/user_postgres.go
type userRepository struct {
    db *pgxpool.Pool
}

func NewUserRepository(db *pgxpool.Pool) domain.UserRepository {
    return &userRepository{db: db}
}

func (r *userRepository) GetByID(ctx context.Context, id uuid.UUID) (*domain.User, error) {
    const q = `SELECT id, email, name, created_at FROM users WHERE id = $1`

    var u domain.User
    err := r.db.QueryRow(ctx, q, id).Scan(&u.ID, &u.Email, &u.Name, &u.CreatedAt)
    if errors.Is(err, pgx.ErrNoRows) {
        return nil, domain.ErrNotFound
    }
    return &u, err
}
```

**Use `sqlc` for complex queries.** Define SQL in `.sql` files, run `sqlc generate`, get type-safe Go code.

---

## 7. Migrations

Use **`golang-migrate`** or **`goose`**. Run migrations at startup or via a separate init container in Kubernetes.

```go
// internal/repository/migrate.go
package repository

import (
    "github.com/golang-migrate/migrate/v4"
    _ "github.com/golang-migrate/migrate/v4/database/pgx/v5"
    _ "github.com/golang-migrate/migrate/v4/source/file"
)

func RunMigrations(dsn, migrationsPath string) error {
    m, err := migrate.New("file://"+migrationsPath, dsn)
    if err != nil {
        return err
    }
    if err := m.Up(); err != nil && err != migrate.ErrNoChange {
        return err
    }
    return nil
}
```

Migration file naming: `000001_create_users.up.sql` / `000001_create_users.down.sql`.

```sql
-- migrations/000001_create_users.up.sql
CREATE TABLE users (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email      TEXT NOT NULL UNIQUE,
    name       TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
```

---

## 8. Logging

Use **`log/slog`** (Go 1.21+). Structured, fast, zero external dependency.

```go
// internal/telemetry/logger.go
package telemetry

import (
    "log/slog"
    "os"
)

func SetupLogger(level, env string) {
    var lvl slog.Level
    _ = lvl.UnmarshalText([]byte(level))

    var handler slog.Handler
    if env == "production" {
        handler = slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: lvl})
    } else {
        handler = slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{Level: lvl})
    }

    slog.SetDefault(slog.New(handler))
}
```

**Always pass context to propagate trace IDs:**

```go
slog.InfoContext(ctx, "user created", "user_id", user.ID, "email", user.Email)
```

Add a `slog.Handler` wrapper that reads the OTEL trace ID from context and injects it automatically:

```go
type otelHandler struct{ slog.Handler }

func (h *otelHandler) Handle(ctx context.Context, r slog.Record) error {
    if span := trace.SpanFromContext(ctx); span.IsRecording() {
        sc := span.SpanContext()
        r.AddAttrs(
            slog.String("trace_id", sc.TraceID().String()),
            slog.String("span_id",  sc.SpanID().String()),
        )
    }
    return h.Handler.Handle(ctx, r)
}
```

---

## 9. Observability: Metrics, Tracing, Profiling

Use **OpenTelemetry** for tracing and metrics. One SDK, pluggable backends (Jaeger, Tempo, Prometheus, Datadog).

```go
// internal/telemetry/otel.go
package telemetry

import (
    "context"
    "time"

    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
    "go.opentelemetry.io/otel/exporters/prometheus"
    "go.opentelemetry.io/otel/sdk/metric"
    "go.opentelemetry.io/otel/sdk/resource"
    sdktrace "go.opentelemetry.io/otel/sdk/trace"
    semconv "go.opentelemetry.io/otel/semconv/v1.21.0"
    "myservice/internal/config"
)

func Setup(ctx context.Context, cfg config.OTELConfig) (func(context.Context) error, error) {
    res, _ := resource.New(ctx,
        resource.WithAttributes(semconv.ServiceName(cfg.ServiceName)),
    )

    // Tracing
    traceExp, err := otlptracegrpc.New(ctx,
        otlptracegrpc.WithEndpoint(cfg.Endpoint),
        otlptracegrpc.WithInsecure(),
    )
    if err != nil {
        return nil, err
    }

    tp := sdktrace.NewTracerProvider(
        sdktrace.WithBatcher(traceExp),
        sdktrace.WithResource(res),
        sdktrace.WithSampler(sdktrace.TraceIDRatioBased(cfg.SamplingRatio)),
    )
    otel.SetTracerProvider(tp)

    // Metrics via Prometheus exporter
    promExp, _ := prometheus.New()
    mp := metric.NewMeterProvider(
        metric.WithReader(promExp),
        metric.WithResource(res),
    )
    otel.SetMeterProvider(mp)

    return func(ctx context.Context) error {
        ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
        defer cancel()
        _ = tp.Shutdown(ctx)
        _ = mp.Shutdown(ctx)
        return nil
    }, nil
}
```

**Expose Prometheus metrics endpoint:**

```go
import "github.com/prometheus/client_golang/prometheus/promhttp"

r.Handle("/metrics", promhttp.Handler())
```

**Use pprof in non-production:**

```go
import _ "net/http/pprof"
// automatically available at /debug/pprof/ when you register on a separate port
```

---

## 10. Error Handling

Define sentinel errors in the domain layer. Never return raw DB or framework errors to the caller.

```go
// internal/domain/errors.go
package domain

import "errors"

var (
    ErrNotFound      = errors.New("not found")
    ErrAlreadyExists = errors.New("already exists")
    ErrUnauthorized  = errors.New("unauthorized")
    ErrForbidden     = errors.New("forbidden")
    ErrInvalidInput  = errors.New("invalid input")
)
```

Map to HTTP status in the handler layer:

```go
func handleUsecaseError(w http.ResponseWriter, err error) {
    switch {
    case errors.Is(err, domain.ErrNotFound):
        respondError(w, http.StatusNotFound, err.Error())
    case errors.Is(err, domain.ErrAlreadyExists):
        respondError(w, http.StatusConflict, err.Error())
    case errors.Is(err, domain.ErrUnauthorized):
        respondError(w, http.StatusUnauthorized, err.Error())
    case errors.Is(err, domain.ErrForbidden):
        respondError(w, http.StatusForbidden, err.Error())
    case errors.Is(err, domain.ErrInvalidInput):
        respondError(w, http.StatusUnprocessableEntity, err.Error())
    default:
        slog.Error("unexpected error", "error", err)
        respondError(w, http.StatusInternalServerError, "internal server error")
    }
}
```

Use `fmt.Errorf("userUC.Create: %w", err)` to wrap with context without losing the sentinel.

---

## 11. Middleware

### Request ID

```go
func RequestID(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        id := r.Header.Get("X-Request-ID")
        if id == "" {
            id = uuid.New().String()
        }
        ctx := context.WithValue(r.Context(), ctxKeyRequestID{}, id)
        w.Header().Set("X-Request-ID", id)
        next.ServeHTTP(w, r.WithContext(ctx))
    })
}
```

### Rate Limiting

```go
import "golang.org/x/time/rate"

func RateLimiter(rps int) func(http.Handler) http.Handler {
    limiter := rate.NewLimiter(rate.Limit(rps), rps*2)
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            if !limiter.Allow() {
                respondError(w, http.StatusTooManyRequests, "rate limit exceeded")
                return
            }
            next.ServeHTTP(w, r)
        })
    }
}
```

For per-IP rate limiting, use **`github.com/ulule/limiter`** with Redis backend.

### Timeout

```go
func Timeout(d time.Duration) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.TimeoutHandler(next, d, `{"error":"request timeout"}`)
    }
}
```

---

## 12. Authentication & Authorization

### JWT Validation Middleware

```go
// internal/middleware/auth.go
func Auth(cfg config.AuthConfig) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            header := r.Header.Get("Authorization")
            if !strings.HasPrefix(header, "Bearer ") {
                respondError(w, http.StatusUnauthorized, "missing token")
                return
            }

            claims, err := parseJWT(strings.TrimPrefix(header, "Bearer "), cfg.JWTSecret)
            if err != nil {
                respondError(w, http.StatusUnauthorized, "invalid token")
                return
            }

            ctx := context.WithValue(r.Context(), ctxKeyClaims{}, claims)
            next.ServeHTTP(w, r.WithContext(ctx))
        })
    }
}
```

### RBAC

Keep roles simple. Encode them in the JWT claims. Check in the usecase layer, not the handler:

```go
func (uc *userUsecase) Delete(ctx context.Context, id uuid.UUID) error {
    claims := auth.ClaimsFromContext(ctx)
    if !claims.HasRole("admin") {
        return domain.ErrForbidden
    }
    return uc.repo.Delete(ctx, id)
}
```

For complex policy needs, use **Open Policy Agent (OPA)** as a sidecar.

---

## 13. Message Queue / Event Streaming

Use **`segmentio/kafka-go`** for Kafka or **`nats-io/nats.go`** for NATS.

**Publisher:**

```go
// internal/event/publisher.go
type Publisher struct {
    writer *kafka.Writer
}

func NewPublisher(brokers []string, topic string) *Publisher {
    return &Publisher{
        writer: &kafka.Writer{
            Addr:         kafka.TCP(brokers...),
            Topic:        topic,
            Balancer:     &kafka.LeastBytes{},
            RequiredAcks: kafka.RequireAll,
            Async:        false,
        },
    }
}

func (p *Publisher) Publish(ctx context.Context, key string, payload any) error {
    data, err := json.Marshal(payload)
    if err != nil {
        return err
    }
    return p.writer.WriteMessages(ctx, kafka.Message{
        Key:   []byte(key),
        Value: data,
    })
}
```

**Consumer with retry:**

```go
func (c *Consumer) Consume(ctx context.Context, handler func(ctx context.Context, msg kafka.Message) error) {
    for {
        msg, err := c.reader.FetchMessage(ctx)
        if err != nil {
            if ctx.Err() != nil {
                return
            }
            slog.ErrorContext(ctx, "fetch message failed", "error", err)
            continue
        }

        if err := handler(ctx, msg); err != nil {
            slog.ErrorContext(ctx, "handler failed", "error", err, "offset", msg.Offset)
            // send to DLQ or retry with backoff
            continue
        }

        _ = c.reader.CommitMessages(ctx, msg)
    }
}
```

---

## 14. Caching

Use **`go-redis/redis/v9`**. Always set TTLs. Use `SETNX` for distributed locks.

```go
// internal/repository/user_cache.go
type userCacheRepository struct {
    next  domain.UserRepository
    redis *redis.Client
    ttl   time.Duration
}

func (r *userCacheRepository) GetByID(ctx context.Context, id uuid.UUID) (*domain.User, error) {
    key := fmt.Sprintf("user:%s", id)

    data, err := r.redis.Get(ctx, key).Bytes()
    if err == nil {
        var u domain.User
        _ = json.Unmarshal(data, &u)
        return &u, nil
    }

    u, err := r.next.GetByID(ctx, id)
    if err != nil {
        return nil, err
    }

    data, _ = json.Marshal(u)
    _ = r.redis.Set(ctx, key, data, r.ttl).Err()
    return u, nil
}
```

**Cache invalidation:** on update/delete, `DEL` the key. On write-heavy paths, use write-through or write-behind.

---

## 15. Graceful Shutdown

```go
// internal/server/server.go
func (s *Server) Run() {
    ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
    defer stop()

    eg, ctx := errgroup.WithContext(ctx)

    eg.Go(func() error {
        slog.Info("HTTP server starting", "port", s.cfg.HTTP.Port)
        if err := s.http.ListenAndServe(); !errors.Is(err, http.ErrServerClosed) {
            return err
        }
        return nil
    })

    eg.Go(func() error {
        slog.Info("gRPC server starting", "port", s.cfg.GRPC.Port)
        return ListenGRPC(s.cfg, s.grpc)
    })

    // Wait for signal
    <-ctx.Done()
    slog.Info("shutdown signal received")

    shutdownCtx, cancel := context.WithTimeout(context.Background(), s.cfg.HTTP.ShutdownTimeout)
    defer cancel()

    s.http.Shutdown(shutdownCtx)
    s.grpc.GracefulStop()

    if err := eg.Wait(); err != nil {
        slog.Error("server error", "error", err)
        os.Exit(1)
    }

    slog.Info("server stopped cleanly")
}
```

---

## 16. Health Checks & Readiness Probes

```go
// internal/handler/health.go
type HealthHandler struct {
    db    *pgxpool.Pool
    redis *redis.Client
}

func (h *HealthHandler) Readyz(w http.ResponseWriter, r *http.Request) {
    type check struct {
        Status string `json:"status"`
        Error  string `json:"error,omitempty"`
    }
    type response struct {
        Status string            `json:"status"`
        Checks map[string]check  `json:"checks"`
    }

    res := response{Status: "ok", Checks: map[string]check{}}
    code := http.StatusOK

    if err := h.db.Ping(r.Context()); err != nil {
        res.Checks["database"] = check{Status: "fail", Error: err.Error()}
        res.Status = "fail"
        code = http.StatusServiceUnavailable
    } else {
        res.Checks["database"] = check{Status: "ok"}
    }

    if err := h.redis.Ping(r.Context()).Err(); err != nil {
        res.Checks["redis"] = check{Status: "fail", Error: err.Error()}
        res.Status = "fail"
        code = http.StatusServiceUnavailable
    } else {
        res.Checks["redis"] = check{Status: "ok"}
    }

    respondJSON(w, code, res)
}

func Healthz(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
}
```

---

## 17. Testing Strategy

### Unit Tests

Test usecases with mock repositories. Use **`testify/mock`** or **`uber-go/mock`**.

```go
func TestUserUsecase_Create(t *testing.T) {
    mockRepo := mocks.NewUserRepository(t)
    uc := usecase.NewUserUsecase(mockRepo, nil)

    mockRepo.EXPECT().
        Create(mock.Anything, mock.MatchedBy(func(u *domain.User) bool {
            return u.Email == "test@example.com"
        })).
        Return(nil)

    user, err := uc.Create(context.Background(), domain.User{Email: "test@example.com", Name: "Test"})
    require.NoError(t, err)
    assert.Equal(t, "test@example.com", user.Email)
}
```

### Integration Tests

Use **`testcontainers-go`** to spin up real Postgres and Redis:

```go
func TestUserRepository(t *testing.T) {
    ctx := context.Background()

    pgContainer, err := postgres.Run(ctx, "postgres:16-alpine",
        postgres.WithDatabase("testdb"),
        postgres.WithUsername("test"),
        postgres.WithPassword("test"),
        testcontainers.WithWaitStrategy(wait.ForLog("database system is ready")),
    )
    require.NoError(t, err)
    defer pgContainer.Terminate(ctx)

    dsn, _ := pgContainer.ConnectionString(ctx, "sslmode=disable")
    db, _ := repository.NewPostgresDB(config.DatabaseConfig{DSN: dsn, MaxOpenConns: 5, MaxIdleConns: 2})

    // Run migrations
    repository.RunMigrations(dsn, "../../migrations")

    repo := repository.NewUserRepository(db)

    t.Run("create and get", func(t *testing.T) {
        u := &domain.User{Email: "a@b.com", Name: "A B"}
        err := repo.Create(ctx, u)
        require.NoError(t, err)

        got, err := repo.GetByID(ctx, u.ID)
        require.NoError(t, err)
        assert.Equal(t, u.Email, got.Email)
    })
}
```

### HTTP Tests

```go
func TestUserHandler_Create(t *testing.T) {
    mockUC := mocks.NewUserUsecase(t)
    h := handler.NewUserHandler(mockUC)

    mockUC.EXPECT().Create(mock.Anything, mock.Anything).
        Return(&domain.User{ID: uuid.New(), Email: "x@y.com"}, nil)

    body := `{"email":"x@y.com","name":"X Y"}`
    req := httptest.NewRequest(http.MethodPost, "/api/v1/users", strings.NewReader(body))
    req.Header.Set("Content-Type", "application/json")
    w := httptest.NewRecorder()

    h.Create(w, req)

    assert.Equal(t, http.StatusCreated, w.Code)
}
```

**Run with race detector in CI:** `go test -race ./...`

---

## 18. Dockerfile & Container Hardening

```dockerfile
# Build stage
FROM golang:1.23-alpine AS builder

RUN apk add --no-cache git ca-certificates tzdata

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -ldflags="-s -w -X main.version=${VERSION}" \
    -o /app/server ./cmd/server

# Final stage — distroless for minimal attack surface
FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /app/server /server
COPY --from=builder /app/migrations /migrations

USER nonroot:nonroot

EXPOSE 8080 9090

ENTRYPOINT ["/server"]
```

**Key points:**

- `distroless/static:nonroot` — no shell, no package manager, no root.
- `-s -w` strips debug info → smaller binary.
- `CGO_ENABLED=0` → fully static binary, no libc dependency.
- Separate build and runtime stages.

---

## 19. CI/CD Pipeline (GitHub Actions)

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:

env:
  GO_VERSION: "1.23"
  IMAGE_NAME: ghcr.io/${{ github.repository }}

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
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-go@v5
        with:
          go-version: ${{ env.GO_VERSION }}
          cache: true

      - name: Lint
        uses: golangci/golangci-lint-action@v6
        with:
          version: latest

      - name: Test
        run: go test -race -coverprofile=coverage.out ./...
        env:
          DB_DSN: postgres://test:test@localhost:5432/testdb?sslmode=disable

      - name: Coverage gate
        run: |
          COVERAGE=$(go tool cover -func=coverage.out | grep total | awk '{print $3}' | tr -d '%')
          if (( $(echo "$COVERAGE < 70" | bc -l) )); then
            echo "Coverage $COVERAGE% is below 70%" && exit 1
          fi

  build:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          push: true
          tags: ${{ env.IMAGE_NAME }}:${{ github.sha }},${{ env.IMAGE_NAME }}:latest
          build-args: VERSION=${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: Scan image
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ env.IMAGE_NAME }}:${{ github.sha }}
          exit-code: "1"
          severity: CRITICAL
```

---

## 20. Kubernetes Manifests

```yaml
# deploy/k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myservice
  labels:
    app: myservice
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: myservice
  template:
    metadata:
      labels:
        app: myservice
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
    spec:
      serviceAccountName: myservice
      securityContext:
        runAsNonRoot: true
        runAsUser: 65532
        fsGroup: 65532
      terminationGracePeriodSeconds: 30
      containers:
        - name: myservice
          image: ghcr.io/myorg/myservice:latest
          ports:
            - containerPort: 8080
              name: http
            - containerPort: 9090
              name: grpc
          envFrom:
            - configMapRef:
                name: myservice-config
            - secretRef:
                name: myservice-secrets
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
            limits:
              cpu: 500m
              memory: 256Mi
          livenessProbe:
            httpGet:
              path: /healthz
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /readyz
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
            failureThreshold: 3
          lifecycle:
            preStop:
              exec:
                command: ["/bin/sh", "-c", "sleep 5"]
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop: [ALL]
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
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

---

## 21. Security Checklist

```
[ ] Secrets never in environment variable names — use secretRef, not plain env
[ ] JWT: RS256 or EdDSA, not HS256 with shared secret across services
[ ] TLS enforced for all inter-service communication (mTLS via service mesh or certs)
[ ] All inputs validated at HTTP boundary (use go-playground/validator)
[ ] SQL: parameterized queries only — never fmt.Sprintf into SQL
[ ] Dependency audit: govulncheck ./... passes clean
[ ] Container: non-root, read-only filesystem, no capabilities
[ ] Rate limiting on all public endpoints
[ ] CORS configured explicitly — never wildcard in production
[ ] Sensitive fields (passwords, tokens) never logged — annotate with slog:"-" equivalent
[ ] Timeout on every outbound HTTP call (http.Client with Timeout set)
[ ] Context cancellation propagated through all DB and cache calls
[ ] No default credentials — startup fails without required secrets
[ ] API versioning in URL (/api/v1) to allow breaking changes safely
[ ] PodDisruptionBudget set — prevents all pods being killed during node drain
```

---

## 22. Production Checklist

```
[ ] Structured JSON logging in production, text in dev
[ ] Trace ID injected into every log line
[ ] OTEL traces exported to backend (Tempo / Jaeger / Datadog)
[ ] Prometheus /metrics endpoint scraped by cluster
[ ] Alerts defined: error rate, p99 latency, pod restarts, DB connection pool exhaustion
[ ] Graceful shutdown tested: SIGTERM → drain → stop within terminationGracePeriodSeconds
[ ] Readiness probe fails during migration / startup — traffic not sent prematurely
[ ] Resource requests/limits set on every container
[ ] HPA configured — tested under synthetic load
[ ] PodDisruptionBudget prevents zero-replica situations during node drains
[ ] Database connection pool sized correctly for expected concurrency
[ ] Slow query logging enabled (Postgres log_min_duration_statement = 100ms)
[ ] Migration run separately before rolling deployment (init container or job)
[ ] Image scanned for CVEs in CI (Trivy / Snyk) — critical severity blocks merge
[ ] SBOM generated and stored alongside image
[ ] Runbook exists for: service down, high error rate, DB failover, rollback procedure
[ ] On-call rotation configured with escalation policy
```

---

## Key Dependencies Reference

| Concern         | Library                                       |
| --------------- | --------------------------------------------- |
| Config          | `github.com/ilyakaznacheev/cleanenv`          |
| HTTP router     | `github.com/go-chi/chi/v5`                    |
| gRPC            | `google.golang.org/grpc`                      |
| Postgres driver | `github.com/jackc/pgx/v5`                     |
| SQL query gen   | `github.com/sqlc-dev/sqlc`                    |
| Redis           | `github.com/redis/go-redis/v9`                |
| Migrations      | `github.com/golang-migrate/migrate`           |
| Observability   | `go.opentelemetry.io/otel`                    |
| Kafka           | `github.com/segmentio/kafka-go`               |
| Validation      | `github.com/go-playground/validator`          |
| JWT             | `github.com/golang-jwt/jwt/v5`                |
| Mocks           | `github.com/uber-go/mock`                     |
| Test containers | `github.com/testcontainers/testcontainers-go` |
| Test assertions | `github.com/stretchr/testify`                 |
| Rate limiter    | `golang.org/x/time/rate`                      |
| Error grouping  | `golang.org/x/sync/errgroup`                  |
| Linter          | `github.com/golangci/golangci-lint`           |
| Vuln scanner    | `golang.org/x/vuln/cmd/govulncheck`           |

---

## Makefile

```makefile
.PHONY: build test lint migrate proto docker run

GO := go
SERVICE := myservice
VERSION ?= $(shell git rev-parse --short HEAD)

build:
	CGO_ENABLED=0 go build -ldflags="-s -w -X main.version=$(VERSION)" -o bin/$(SERVICE) ./cmd/server

test:
	go test -race -cover ./...

lint:
	golangci-lint run ./...

vuln:
	govulncheck ./...

migrate:
	go run ./cmd/migrate/main.go

proto:
	buf generate

docker:
	docker build --build-arg VERSION=$(VERSION) -t $(SERVICE):$(VERSION) .

run:
	APP_ENV=development \
	DB_DSN=postgres://postgres:postgres@localhost:5432/myservice?sslmode=disable \
	REDIS_ADDR=localhost:6379 \
	JWT_SECRET=dev-secret \
	go run ./cmd/server
```

---

_This guide reflects production patterns as of Go 1.23 and represents a pragmatic balance between simplicity and enterprise readiness. Start with what you need, add the rest as you scale._
