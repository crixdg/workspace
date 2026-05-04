# Go Project Guidelines

> Opinionated rules for Go microservices. Searchable by concern.
> Deep language reference → `golang-expertise.md`
> Production bootstrap steps → `go-microservice-bootstrap.md`

---

## Table of Contents

1. [I. Project Layout](#i-project-layout)
2. [II. Naming Quick Reference](#ii-naming-quick-reference)
3. [III. Layer Responsibilities](#iii-layer-responsibilities)
4. [IV. Dependency Rules Between Layers](#iv-dependency-rules-between-layers)
5. [V. Configuration](#v-configuration)
6. [VI. Logging](#vi-logging)
7. [VII. Error Handling](#vii-error-handling)
8. [VIII. Interfaces](#viii-interfaces)
9. [IX. Database & Transactions](#ix-database--transactions)
10. [X. Context](#x-context)
11. [XI. internal/server](#xi-internalserver)
12. [XII. HTTP Handlers](#xii-http-handlers)
13. [XIII. Concurrency Rules](#xiii-concurrency-rules)
14. [XIV. cmd/server/main.go](#xiv-cmdservermain-go)
15. [XV. Infrastructure Init Order](#xv-infrastructure-init-order)
16. [XVI. Testing](#xvi-testing)
17. [XVII. Common Pitfalls](#xvii-common-pitfalls)

---

## I. Project Layout

### I.1 Single service

```
myservice/
├── cmd/
│   └── server/
│       └── main.go           # composition root — thin
├── internal/
│   ├── config/
│   ├── domain/               # entities + repository interfaces
│   ├── usecase/              # application logic
│   ├── repository/           # DB/cache implementations
│   ├── handler/              # HTTP/gRPC — thin, calls usecases
│   ├── middleware/
│   ├── server/               # server wiring (HTTP + gRPC)
│   └── telemetry/
├── api/proto/
├── migrations/
└── deploy/
```

### I.2 Monorepo (multiple services, same repo)

Two valid options depending on scale:

#### I.2.1 Option A — Single `go.mod` (small team, ≤ 5 services)

All services share one module. Service-private code lives under `internal/<service>/`; shared infrastructure lives under `internal/shared/`.

```
myrepo/
├── cmd/
│   ├── account/
│   │   └── main.go
│   └── notification/
│       └── main.go
├── internal/
│   ├── account/              # account-service private code
│   │   ├── domain/
│   │   ├── usecase/
│   │   ├── repository/
│   │   └── handler/
│   ├── notification/         # notification-service private code
│   │   ├── domain/
│   │   ├── usecase/
│   │   ├── repository/
│   │   └── handler/
│   └── shared/               # cross-service shared code
│       ├── middleware/
│       ├── telemetry/
│       ├── db/
│       └── config/
├── api/
│   └── proto/
├── migrations/
│   ├── account/
│   └── notification/
├── deploy/
├── go.mod                    # module: github.com/org/myrepo
└── go.sum
```

**Import rules with single `go.mod`:**
- `internal/account/` may import `internal/shared/` ✓
- `internal/account/` may NOT import `internal/notification/` ✗
- `cmd/account/main.go` is the only file that wires `internal/account/` ✓

#### I.2.2 Option B — Multi-module with `go.work` (larger team, independent deploy cycles)

Each service is its own Go module with its own `go.mod` and `internal/`. Shared libraries are separate modules. `go.work` glues them together locally without `replace` directives.

```
myrepo/
├── services/
│   ├── account/
│   │   ├── cmd/server/main.go
│   │   ├── internal/
│   │   │   ├── domain/
│   │   │   ├── usecase/
│   │   │   ├── repository/
│   │   │   └── handler/
│   │   ├── migrations/
│   │   └── go.mod            # module: github.com/org/myrepo/services/account
│   └── notification/
│       ├── cmd/server/main.go
│       ├── internal/
│       └── go.mod            # module: github.com/org/myrepo/services/notification
├── lib/                      # shared libraries — each is its own module
│   ├── telemetry/
│   │   └── go.mod            # module: github.com/org/myrepo/lib/telemetry
│   ├── middleware/
│   │   └── go.mod
│   └── db/
│       └── go.mod
├── api/proto/
├── deploy/
└── go.work                   # ties all modules for local dev
```

`go.work`:
```
go 1.23

use (
    ./services/account
    ./services/notification
    ./lib/telemetry
    ./lib/middleware
    ./lib/db
)
```

**When to pick which:**

| | Option A (single `go.mod`) | Option B (`go.work`) |
|---|---|---|
| Team size | Small (1–5 devs) | Medium–large |
| Deploy | All services deploy together or via Docker build targets | Services deploy independently |
| Shared deps | Same version for all services | Each service pins its own versions |
| CI | Single `go test ./...` | Per-service pipelines |
| Complexity | Low | Medium |

**Rules (both options):**
- `internal/` — everything lives here; code under `internal/<service>/` is private to that service
- Service A must never import from Service B's `internal/` — extract to `shared/` or `lib/` first
- Shared code must have no knowledge of any specific service
- One package = one clearly nameable purpose; if you can't name it, split it differently
- Keep test files next to the code they test (`foo_test.go` beside `foo.go`)

---

## II. Naming Quick Reference

```
Variables
  ctx       context.Context
  err       error
  id        identifier (string or int)
  buf       []byte or bytes.Buffer
  cfg       Config
  req       request struct or *http.Request
  resp      response struct or *http.Response
  db        *pgxpool.Pool or *sql.DB
  tx        transaction
  w, r      http.ResponseWriter, *http.Request
  wg        sync.WaitGroup
  mu        sync.Mutex

Acronyms — all caps or all lower, never mixed
  userID    ✓     userId    ✗
  userURL   ✓     userUrl   ✗
  getAPIKey ✓     getApiKey ✗
  httpClient ✓    HTTPClient ✗ (package prefix stays lowercase)

Functions — start with a verb
  CreateUser, GetAccount, UpdateOrder, DeleteSession
  ListProducts, ParseToken, ValidateInput
  IsActive, HasPermission          (booleans)

Getters — omit "Get"
  func (u *User) Email() string    not GetEmail()
  func (a *Account) Status()       not GetStatus()

Packages — lowercase, single word, no underscores
  middleware, repository, usecase, handler
  NOT: user_handler, UserHandler

Receivers — 1-2 letter abbreviation of the type
  func (u *UserHandler) ...
  func (r *UserRepository) ...
```

---

## III. Layer Responsibilities

| Layer | Lives in | Does | Does NOT do |
|---|---|---|---|
| **Domain** | `internal/domain/` | Define entities and repository interfaces | Import from any other internal layer |
| **Repository** | `internal/repository/` | Execute queries, map rows to domain types | Business decisions, HTTP, usecase logic |
| **Usecase** | `internal/usecase/` | Orchestrate domain rules, call repositories/external services | HTTP concepts, DB queries, JSON |
| **Handler** | `internal/handler/` | Decode request, validate input, call one usecase, encode response | Business logic, DB access, error wrapping |
| **Server** | `internal/server/` | Mount routes, attach middleware, construct `http.Server` | Business logic, handler logic |

---

## IV. Dependency Rules Between Layers

```
handler → usecase → repository → (DB driver)
                 ↘ domain ↙
```

- `domain/` imports nothing from `internal/`
- `repository/` imports `domain/` only
- `usecase/` imports `domain/` + `repository/` interfaces only
- `handler/` imports `usecase/` only
- `main.go` imports everything (it's the glue)

**Violation detector:** if `domain/` imports `repository/`, or `usecase/` imports `handler/`, something is wrong.

---

## V. Configuration

### V.1 Decision

| System | Library | Reason |
|---|---|---|
| **Multi-module monolith / layered config** | `koanf` v2 | No global state, composable providers, partial env overrides per environment |
| **Simple single service / env-only** | `caarlos0/env` v11+ | Zero deps, struct tags, sufficient when no file config is needed |
| **Avoid** | `spf13/viper` | Global singleton, key-lowercasing bugs, bloated deps, v2 stalled |

Use **koanf** as the central config system for any multi-module repo. `caarlos0/env` is acceptable only as a bootstrapper or for dead-simple services with no layering needs.

#### V.1.1 Why koanf over viper

| Concern | koanf | viper |
|---|---|---|
| Global state | None — instance-based | `viper.Get*` is a global singleton |
| Key case | Preserved as-is | Lowercases all keys (breaks `DB_URL` → `db_url` edge cases) |
| Composability | Stack any providers in any order | Opinionated, limited composition |
| Dependencies | Lean, provider-specific imports | Pulls cobra, mapstructure, etc. |
| Maintenance | Active v2 | v2 stalled for years |

### V.2 Installation

```bash
go get github.com/knadh/koanf/v2
go get github.com/knadh/koanf/providers/confmap
go get github.com/knadh/koanf/providers/file
go get github.com/knadh/koanf/providers/env
go get github.com/knadh/koanf/parsers/yaml
```

Only import the providers you actually use — each is a separate module.

### V.3 Core concepts

```
koanf instance
    └── flat key-value store
            key delimiter: "."  (configurable)
            e.g. "server.port", "database.dsn"
```

```go
k := koanf.New(".")   // "." is the key path delimiter
```

Direct reads (rarely needed — prefer `Unmarshal`):

```go
k.Int("server.port")
k.String("database.dsn")
k.Duration("server.shutdown_timeout")
k.Bool("feature.enabled")
k.Strings("allowed.origins")   // []string
k.Exists("database.dsn")       // bool
```

### V.4 Providers

Providers feed data into a koanf instance. Each `k.Load` call merges over existing keys.

**confmap — in-code defaults:**
```go
k.Load(confmap.Provider(map[string]any{
    "server.port":             8080,
    "server.shutdown_timeout": "30s",
    "database.max_open_conns": 25,
}, "."), nil)
```

Use flat dotted keys. The second arg to `Provider` is the key delimiter — must match `koanf.New(delim)`.

**file — YAML / JSON / TOML:**
```go
if err := k.Load(file.Provider("config.yaml"), yaml.Parser()); err != nil {
    if !os.IsNotExist(err) {
        return nil, fmt.Errorf("config file: %w", err)
    }
    // missing file is OK — env vars cover production
}
```

**env — environment variables:**
```go
k.Load(env.Provider("APP_", ".", func(s string) string {
    s = strings.TrimPrefix(s, "APP_")
    s = strings.ToLower(s)
    return strings.ReplaceAll(s, "_", ".")
}), nil)
// APP_SERVER_PORT=9090 → key "server.port"
```

**rawbytes — in-memory bytes (tests / remote config):**
```go
raw := []byte("server:\n  port: 9090\n")
k.Load(rawbytes.Provider(raw), yaml.Parser())
```

### V.5 Parsers

| Format | Import                       | Parser call       |
| ------ | ---------------------------- | ----------------- |
| YAML   | `knadh/koanf/parsers/yaml`   | `yaml.Parser()`   |
| JSON   | `knadh/koanf/parsers/json`   | `json.Parser()`   |
| TOML   | `knadh/koanf/parsers/toml`   | `toml.Parser()`   |
| dotenv | `knadh/koanf/parsers/dotenv` | `dotenv.Parser()` |

YAML is standard for file-based config. JSON is useful when config comes from an HTTP API.

### V.6 File structure

```
internal/
├── config/
│   ├── loader.go       # Load() — builds koanf instance, layers, unmarshals
│   └── types.go        # root Config struct composed of module sub-structs
├── account/
│   └── config.go       # account.Config — only what account needs
└── auth/
    └── config.go       # auth.Config
```

### V.7 Root config (types.go)

```go
// internal/config/types.go
package config

import (
    "myrepo/internal/account"
    "myrepo/internal/auth"
)

type Config struct {
    Server   ServerConfig   `koanf:"server"`
    Database DatabaseConfig `koanf:"database"`
    Account  account.Config `koanf:"account"`
    Auth     auth.Config    `koanf:"auth"`
}

type ServerConfig struct {
    Port            int           `koanf:"port"`
    ShutdownTimeout time.Duration `koanf:"shutdown_timeout"`
    TLSEnabled      bool          `koanf:"tls_enabled"`
}

type DatabaseConfig struct {
    DSN             string        `koanf:"dsn"`
    MaxOpenConns    int           `koanf:"max_open_conns"`
    ConnMaxLifetime time.Duration `koanf:"conn_max_lifetime"`
}
```

### V.8 Module-scoped config

```go
// internal/account/config.go
package account

import "time"

type Config struct {
    TokenTTL         time.Duration `koanf:"token_ttl"`
    MaxLoginAttempts int           `koanf:"max_login_attempts"`
}
```

### V.9 Struct tags & unmarshalling

Tag every field with `koanf:"<key>"`. The key is the last segment of the dotted path.

**Unmarshal the whole tree:**
```go
var cfg Config
err := k.UnmarshalWithConf("", &cfg, koanf.UnmarshalConf{Tag: "koanf"})
```

**Unmarshal a subtree** (module-scoped loading):
```go
var dbCfg DatabaseConfig
err := k.UnmarshalWithConf("database", &dbCfg, koanf.UnmarshalConf{Tag: "koanf"})
```

Always use `UnmarshalWithConf` with `Tag: "koanf"` — without it koanf falls back to field names, breaking underscore-to-camel mappings.

### V.10 Type handling

**Durations** — koanf parses `time.Duration` from strings automatically:
```go
// defaults map or config file:
"server.shutdown_timeout": "30s"
"auth.token_ttl":          "24h"
"cache.ttl":               "5m30s"
// as env var: APP_SERVER_SHUTDOWN_TIMEOUT=30s
```

**Slices:**
```go
type Config struct {
    AllowedOrigins []string `koanf:"allowed_origins"`
}
```
In YAML:
```yaml
allowed_origins:
  - https://app.example.com
  - https://admin.example.com
```
As env var (comma-separated): `APP_ALLOWED_ORIGINS=https://app.example.com,https://admin.example.com`

**Nested maps:**
```go
type Config struct {
    Labels map[string]string `koanf:"labels"`
}
```
In YAML:
```yaml
labels:
  env: production
  region: us-east-1
```

### V.11 Loader (loader.go)

Loading order: defaults → file → env override. Each layer overwrites the previous.

```go
// internal/config/loader.go
package config

import (
    "github.com/knadh/koanf/v2"
    "github.com/knadh/koanf/providers/confmap"
    "github.com/knadh/koanf/providers/env"
    "github.com/knadh/koanf/providers/file"
    "github.com/knadh/koanf/parsers/yaml"
)

func Load(configPath string) (*Config, error) {
    k := koanf.New(".")

    // Layer 1: hard-coded defaults (always present)
    if err := k.Load(confmap.Provider(defaults(), "."), nil); err != nil {
        return nil, fmt.Errorf("config defaults: %w", err)
    }

    // Layer 2: config file (optional — missing is OK when env rules)
    if err := k.Load(file.Provider(configPath), yaml.Parser()); err != nil {
        if !os.IsNotExist(err) {
            return nil, fmt.Errorf("config file: %w", err)
        }
    }

    // Layer 3: env overrides (highest priority)
    if err := k.Load(env.Provider("APP_", ".", envKeyMapper), nil); err != nil {
        return nil, fmt.Errorf("config env: %w", err)
    }

    var cfg Config
    if err := k.UnmarshalWithConf("", &cfg, koanf.UnmarshalConf{Tag: "koanf"}); err != nil {
        return nil, fmt.Errorf("config unmarshal: %w", err)
    }

    return &cfg, cfg.validate()
}

func envKeyMapper(s string) string {
    s = strings.TrimPrefix(s, "APP_")
    s = strings.ToLower(s)
    return strings.ReplaceAll(s, "_", ".")
}

func defaults() map[string]any {
    return map[string]any{
        "server.port":               8080,
        "server.shutdown_timeout":   "30s",
        "database.max_open_conns":   25,
        "account.token_ttl":         "24h",
        "account.max_login_attempts": 5,
    }
}
```

### V.12 Env var mapping

Convention: `APP_<SECTION>_<KEY>`

| Env var | Dotted key | Struct field |
|---|---|---|
| `APP_SERVER_PORT` | `server.port` | `Config.Server.Port` |
| `APP_DATABASE_DSN` | `database.dsn` | `Config.Database.DSN` |
| `APP_AUTH_TOKEN_TTL` | `auth.token_ttl` | `Config.Auth.TokenTTL` |

**Underscore ambiguity:** `APP_DATABASE_MAX_OPEN_CONNS` maps to `database.max.open.conns` under the simple mapper — not `database.max_open_conns`. Fix with double-underscore as section separator:

```
APP_DATABASE__MAX_OPEN_CONNS → database.max_open_conns
```

```go
func envKeyMapper(s string) string {
    s = strings.TrimPrefix(s, "APP_")
    s = strings.ToLower(s)
    parts := strings.Split(s, "__") // double underscore = level boundary
    return strings.Join(parts, ".")  // single underscore stays in key name
}
```

Or avoid the problem by using single-word key segments (`dsn`, `port`, `ttl`) instead of multi-word ones.

### V.13 Validation

```go
func (c *Config) validate() error {
    var errs []string

    if c.Database.DSN == "" {
        errs = append(errs, "database.dsn is required")
    }
    if c.Server.Port <= 0 || c.Server.Port > 65535 {
        errs = append(errs, "server.port must be 1–65535")
    }
    if c.Auth.TokenTTL <= 0 {
        errs = append(errs, "auth.token_ttl must be positive")
    }

    if len(errs) > 0 {
        return fmt.Errorf("invalid config:\n  %s", strings.Join(errs, "\n  "))
    }
    return nil
}
```

For richer validation, use `go-playground/validator` with struct tags. The `validator.New()` call goes inside `validate()` — config loading only happens once at startup so the allocation cost is irrelevant:

```go
// types.go — annotate structs with validate tags
type DatabaseConfig struct {
    DSN          string `koanf:"dsn"            validate:"required,url"`
    MaxOpenConns int    `koanf:"max_open_conns"  validate:"min=1,max=1000"`
}

type ServerConfig struct {
    Port            int           `koanf:"port"             validate:"min=1,max=65535"`
    ShutdownTimeout time.Duration `koanf:"shutdown_timeout"  validate:"required"`
}

// loader.go — validate() replaces manual checks
func (c *Config) validate() error {
    v := validator.New()
    if err := v.Struct(c); err != nil {
        return fmt.Errorf("invalid config: %w", err)
    }
    return nil
}
```

`Load()` already calls `cfg.validate()` — nothing else to change there:

```go
var cfg Config
if err := k.UnmarshalWithConf("", &cfg, koanf.UnmarshalConf{Tag: "koanf"}); err != nil {
    return nil, fmt.Errorf("config unmarshal: %w", err)
}

return &cfg, cfg.validate()  // ← validator runs here
```

**Module sub-configs are validated automatically.** `v.Struct(c)` traverses nested structs recursively, so tags on `account.Config`, `auth.Config`, etc. are all checked by the single root call — no extra wiring needed:

```go
// internal/account/config.go — just add validate tags, nothing else
type Config struct {
    TokenTTL         time.Duration `koanf:"token_ttl"          validate:"required"`
    MaxLoginAttempts int           `koanf:"max_login_attempts"  validate:"min=1,max=100"`
}
```

**Cross-field rules that can't be expressed as tags** belong in a `validate()` method on that sub-config. Call it from the root `validate()`:

```go
// internal/database/config.go
type Config struct {
    MinPoolSize int `koanf:"min_pool_size" validate:"min=1"`
    MaxPoolSize int `koanf:"max_pool_size" validate:"min=1"`
}

func (c Config) validate() error {
    if c.MinPoolSize > c.MaxPoolSize {
        return fmt.Errorf("min_pool_size (%d) must be ≤ max_pool_size (%d)", c.MinPoolSize, c.MaxPoolSize)
    }
    return nil
}

// internal/config/loader.go — root validate() calls tag check then cross-field checks
func (c *Config) validate() error {
    v := validator.New()
    if err := v.Struct(c); err != nil {
        return fmt.Errorf("invalid config: %w", err)
    }
    if err := c.Database.validate(); err != nil {
        return fmt.Errorf("database config: %w", err)
    }
    return nil
}
```

### V.14 Where config.yaml lives

```
myservice/
├── config.yaml          ← local dev only — gitignored
├── config.example.yaml  ← committed; documents every key, fake secret values
├── .gitignore           ← config.yaml
└── cmd/server/main.go
```

The file is **never hardcoded** in `Load()`. The path comes from a CLI flag with a sensible default:

```go
// cmd/server/main.go
configPath := flag.String("config", "config.yaml", "path to config file")
flag.Parse()

cfg, err := config.Load(*configPath)
```

| Environment | How the path is supplied |
|---|---|
| Local dev | default flag value (`config.yaml` at service root) |
| Docker | `-config /app/config.yaml` in `CMD` or `ENTRYPOINT` |
| Kubernetes | `-config /etc/myservice/config.yaml`; file mounted from a ConfigMap |

**Kubernetes ConfigMap pattern (non-secrets only):**
```yaml
# deploy/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: myservice-config
data:
  config.yaml: |
    server:
      port: 8080
      shutdown_timeout: 30s
    database:
      max_open_conns: 25
---
# deploy/deployment.yaml (relevant excerpts)
volumeMounts:
  - name: config
    mountPath: /etc/myservice
    readOnly: true
volumes:
  - name: config
    configMap:
      name: myservice-config
args: ["-config", "/etc/myservice/config.yaml"]
```

Secrets (`database.dsn`, `auth.jwt_secret`) are never in the ConfigMap — inject them as env vars via `secretRef` and let the env layer in `Load()` override the file values:

```yaml
envFrom:
  - secretRef:
      name: myservice-secrets   # sets APP_DATABASE_DSN, APP_AUTH_JWT_SECRET
```

### V.15 Wiring in main.go

```go
configPath := flag.String("config", "config.yaml", "path to config file")
flag.Parse()

cfg, err := config.Load(*configPath)
if err != nil {
    slog.Error("config", "err", err)
    os.Exit(1)
}

// Pass only the sub-config each module needs
accountUC := accountuc.New(cfg.Account, accountRepo)
authUC    := authuc.New(cfg.Auth, authRepo)
```

### V.16 Testing

Tests skip file and env loading — supply values directly via confmap:

```go
func testConfig(t *testing.T, overrides map[string]any) *Config {
    t.Helper()
    base := map[string]any{
        "server.port":               8080,
        "database.dsn":              "postgres://localhost:5432/testdb",
        "auth.token_ttl":            "1h",
        "account.max_login_attempts": 3,
    }
    for k, v := range overrides {
        base[k] = v
    }
    k := koanf.New(".")
    k.Load(confmap.Provider(base, "."), nil)
    var cfg Config
    if err := k.UnmarshalWithConf("", &cfg, koanf.UnmarshalConf{Tag: "koanf"}); err != nil {
        t.Fatalf("testConfig: %v", err)
    }
    return &cfg
}

// Usage:
cfg := testConfig(t, map[string]any{"auth.token_ttl": "5m"})
```

### V.17 Config file reference

**config.yaml** (checked in — non-secrets only):
```yaml
server:
  port: 8080
  shutdown_timeout: 30s
  tls_enabled: false

database:
  max_open_conns: 25
  conn_max_lifetime: 5m

account:
  token_ttl: 24h
  max_login_attempts: 5

auth:
  access_token_ttl: 15m
  refresh_token_ttl: 168h  # 7d
```

**config.example.yaml** (documents all keys including secrets — commit this, not the real values):
```yaml
database:
  dsn: postgres://user:pass@localhost:5432/mydb?sslmode=disable

auth:
  jwt_secret: your-secret-here
```

**.env.example** (for env-only or Kubernetes workflows):
```dotenv
APP_SERVER_PORT=8080
APP_DATABASE_DSN=postgres://user:pass@localhost:5432/mydb
APP_AUTH_JWT_SECRET=change-me
APP_AUTH_ACCESS_TOKEN_TTL=15m
```

### V.18 Rules
- No package-level config variables — no `var cfg *Config` at package scope
- No `os.Getenv` inside modules — config is injected, never pulled
- Pass sub-config to constructors, never the whole `*Config`
- Validate and crash at startup — never silently use a zero value for a required field
- Never commit `.env` — only `.env.example` or `config.example.yaml`
- In production: inject secrets via Kubernetes `secretRef`; file config for non-secrets only

### V.19 Anti-patterns

```go
// BAD — global state, breaks DI and parallel tests
var GlobalConfig *config.Config
func init() { GlobalConfig, _ = Load("config.yaml") }

// GOOD — pass config explicitly
func NewServer(cfg Config) *Server { ... }
```

```go
// BAD — module pulls its own config at call time
func (r *AccountRepo) Query() {
    dsn := os.Getenv("DATABASE_DSN")
}

// GOOD — injected at construction
func NewAccountRepo(cfg account.Config) *AccountRepo { ... }
```

```go
// BAD — module receives everything
func NewAccountUsecase(cfg *config.Config) *AccountUsecase

// GOOD — module receives only what it needs
func NewAccountUsecase(cfg account.Config) *AccountUsecase
```

```go
// BAD — silently fixing bad config at runtime
if cfg.Server.Port == 0 {
    cfg.Server.Port = 8080
}

// GOOD — crash at startup
if cfg.Server.Port == 0 {
    return nil, errors.New("server.port is required")
}
```

---

## VI. Logging

Use `log/slog` (stdlib, structured, zero-alloc at disabled levels). Initialize once in `main.go`, set as default — all packages use the package-level `slog.*` functions.

### VI.1 Config

```go
// internal/config/types.go
type LogConfig struct {
    Level  string `koanf:"level"  validate:"oneof=debug info warn error"`
    Format string `koanf:"format" validate:"oneof=json text"`
}

type AppConfig struct {
    Name    string `koanf:"name"    validate:"required"`
    Version string `koanf:"version" validate:"required"`
    Env     string `koanf:"env"     validate:"oneof=development staging production"`
}
```

```yaml
# config.yaml
log:
  level: info
  format: json      # text in development, json in production

app:
  name: myservice
  version: v1.2.3
  env: production
```

### VI.2 Setup (internal/telemetry/logger.go)

```go
package telemetry

import (
    "log/slog"
    "os"

    "github.com/org/myservice/internal/config"
)

func NewLogger(log config.LogConfig, app config.AppConfig) *slog.Logger {
    var level slog.Level
    // UnmarshalText accepts "debug", "info", "warn", "error" (case-insensitive)
    if err := level.UnmarshalText([]byte(log.Level)); err != nil {
        level = slog.LevelInfo
    }

    opts := &slog.HandlerOptions{Level: level}

    var handler slog.Handler
    switch log.Format {
    case "text":
        handler = slog.NewTextHandler(os.Stdout, opts)
    default:
        handler = slog.NewJSONHandler(os.Stdout, opts)
    }

    // Attach service-level fields to every log line
    return slog.New(handler).With(
        "service", app.Name,
        "version", app.Version,
        "env",     app.Env,
    )
}
```

### VI.3 Wiring in main.go

```go
// Must come before any other code that logs
logger := telemetry.NewLogger(cfg.Log, cfg.App)
slog.SetDefault(logger)
```

`slog.SetDefault` makes the logger available everywhere via `slog.Info(...)`, `slog.Error(...)` etc. — no logger instance needs to be passed around.

### VI.4 Usage

```go
// Structured key-value pairs — never fmt.Sprintf in the message
slog.Info("user created", "user_id", user.ID, "email", user.Email)
slog.Error("db query failed", "err", err, "query", "get_user")

// Use ErrorContext in handlers — OTEL bridge extracts trace_id from ctx automatically
slog.ErrorContext(ctx, "create user failed", "err", err, "user_id", id)
```

**Production log line (JSON):**
```json
{
  "time": "2024-01-15T10:23:45Z",
  "level": "ERROR",
  "msg": "create user failed",
  "service": "myservice",
  "version": "v1.2.3",
  "env": "production",
  "err": "create user: insert user: duplicate key value",
  "user_id": "u-123"
}
```

### VI.5 Rules

- Structured logging only — no `fmt.Sprintf` in log messages
- Always log at the boundary where you swallow an error (handler or top-level goroutine)
- Log `err` as a key, never embedded in the message string
- Use `slog.ErrorContext(ctx, ...)` not `slog.Error(...)` in request path — ctx carries the trace span
- Don't log every successful request in handlers — the middleware's `requestLogger` does that
- Never log secrets, tokens, or PII
- `slog.SetDefault` is called once in `main.go` before any other logging — never call it in packages

---

## VII. Error Handling

**Sentinel errors in `domain/errors.go` — define first, used by all layers:**
```go
var (
    ErrNotFound   = errors.New("not found")
    ErrConflict   = errors.New("conflict")
    ErrForbidden  = errors.New("forbidden")
)
```

**Wrap with context, once per layer:**
```go
// repository layer — translate DB errors to domain errors at the boundary
if errors.Is(err, pgx.ErrNoRows) {
    return nil, fmt.Errorf("get user %s: %w", id, domain.ErrNotFound)
}
return nil, fmt.Errorf("get user %s: %w", id, err)

// usecase layer — add usecase context
return nil, fmt.Errorf("create user: %w", err)

// handler layer — translate to HTTP status, never expose internals
```

**Handler error translation:**
```go
func handleUsecaseError(w http.ResponseWriter, err error) {
    switch {
    case errors.Is(err, domain.ErrNotFound):
        respondError(w, http.StatusNotFound, "resource not found")
    case errors.Is(err, domain.ErrConflict):
        respondError(w, http.StatusConflict, "resource already exists")
    case errors.Is(err, domain.ErrForbidden):
        respondError(w, http.StatusForbidden, "forbidden")
    default:
        slog.Error("unhandled error", "err", err)
        respondError(w, http.StatusInternalServerError, "internal error")
    }
}
```

**Rules:**
- Never `log` + `return err` in the same place — either log it (terminal) or return it (propagate), not both
- Never expose raw DB errors to the HTTP response
- `errors.Is` / `errors.As` for checking wrapped errors — never string matching
- Repository translates `sql.ErrNoRows` → `domain.ErrNotFound` at the boundary, never leaks DB errors upward
- Panic only for truly unrecoverable programmer errors (not user errors, not network errors)

### VII.1 Logging nested errors in production
[[#Anti-patterns]]
Wrap errors at each layer so the final `err.Error()` string is a readable call chain. Log once at the terminal boundary (handler or top-level goroutine) with all cross-cutting trace fields alongside it.

**Wrapping prefix rules — what to write in `fmt.Errorf`:**
- Name the operation at *this layer*, not the layer below — each prefix must add new context
- Repository prefixes name the query: `"insert user"`, `"get user %s"`, `"list orders by account %s"`
- Usecase prefixes name the business operation: `"create user"`, `"place order"`
- Never include `"failed"`, `"error"`, or `"err"` in the prefix — it's always an error; the word is noise
- Only wrap if you're adding context. If the inner error is already self-describing, return it as-is

**Good chain:**
```go
// repository
return nil, fmt.Errorf("insert user: %w", err)
// → "insert user: duplicate key value"

// usecase
return nil, fmt.Errorf("create user: %w", err)
// → "create user: insert user: duplicate key value"   ✓ each prefix is distinct
```

**Bad chain — common mistakes:**
```go
// BAD — both layers use the same prefix
// repository
return nil, fmt.Errorf("create user: %w", err)
// usecase
return nil, fmt.Errorf("create user: %w", err)
// → "create user: create user: duplicate key value"   ✗ redundant

// BAD — "failed" adds nothing
return nil, fmt.Errorf("create user failed: %w", err)
// → "create user failed: insert user: duplicate key value"   ✗ verbose

// BAD — wrapping where the inner error already tells the full story
if errors.Is(err, domain.ErrNotFound) {
    return nil, fmt.Errorf("user not found: %w", err)  // err.Error() is already "not found"
}
// → "user not found: not found"   ✗ duplicated meaning
// GOOD — add the parameter that identifies *which* user
return nil, fmt.Errorf("get user %s: %w", id, domain.ErrNotFound)
// → "get user u-123: not found"   ✓
```

**Wrapping convention — each layer adds its operation prefix:**
```go
// repository — name the query; include identifying parameters
if errors.Is(err, pgx.ErrNoRows) {
    return nil, fmt.Errorf("get user %s: %w", id, domain.ErrNotFound)
}
return nil, fmt.Errorf("insert user: %w", err)

// usecase — name the business operation; only wrap if adding new context
return nil, fmt.Errorf("create user: %w", err)
// produces: "create user: insert user: duplicate key value"

// handler — log the full chain exactly once
slog.ErrorContext(ctx, "create user request failed",
    "err",        err,
    "request_id", reqID,
    "user_id",    userID,
)
```

**What the production log entry looks like:**
```json
{
  "time": "2024-01-15T10:23:45Z",
  "level": "ERROR",
  "msg": "create user request failed",
  "err": "create user: get user u-123: not found",
  "request_id": "req-abc-123",
  "trace_id": "4bf92f3577b34da6a3ce929d0e0e4736",
  "user_id": "u-456"
}
```

**Context carrier — thread trace fields through ctx, extract once at log site:**
```go
// middleware — inject at request boundary
ctx = context.WithValue(ctx, ctxKeyRequestID, uuid.New().String())

// helper — collect all cross-cutting log fields from context
func logFields(ctx context.Context, extra ...any) []any {
    base := []any{
        "request_id", RequestIDFromCtx(ctx),
        "trace_id",   TraceIDFromCtx(ctx),
    }
    return append(base, extra...)
}

// handler — one call, full picture
slog.ErrorContext(ctx, "create user request failed",
    logFields(ctx, "err", err, "user_id", userID)...,
)
```

**Structured error type — when you need machine-queryable fields in Loki/Datadog:**

Only add this if your team actively queries `failed_op` in dashboards. Default to plain wrapping above.

```go
// domain/errors.go
type OpError struct {
    Op  string // "get_user", "create_order" — snake_case, log-queryable
    Err error
}

func (e *OpError) Error() string { return e.Op + ": " + e.Err.Error() }
func (e *OpError) Unwrap() error { return e.Err }

// repository usage
return nil, &domain.OpError{Op: "get_user", Err: domain.ErrNotFound}

// handler — extract structured field at log boundary
var opErr *domain.OpError
if errors.As(err, &opErr) {
    slog.ErrorContext(ctx, "request failed",
        logFields(ctx, "err", err.Error(), "failed_op", opErr.Op)...,
    )
} else {
    slog.ErrorContext(ctx, "request failed", logFields(ctx, "err", err)...)
}
```

**Logging rules for nested errors:**
- Use `slog.ErrorContext(ctx, ...)` not `slog.Error(...)` — the OTEL log bridge auto-correlates `trace_id` when ctx carries a span
- `err` field is always the full wrapped string — never truncate or paraphrase it
- `request_id` and `trace_id` must appear on every error log — these are the primary search keys in any log aggregator
- Include entity IDs (`user_id`, `order_id`) as separate structured fields, not embedded in the message string
- Never log the same error at more than one layer — wrapping propagates it, the terminal layer logs it

---

## VIII. Interfaces

**Define interfaces at the consumer, not the producer:**
```go
// BAD — repository defines its own interface
// internal/repository/user_repository.go
type UserRepository interface { ... }

// GOOD — usecase defines what it needs
// internal/usecase/user_usecase.go
type userRepository interface {
    GetByID(ctx context.Context, id string) (*domain.User, error)
    Create(ctx context.Context, user *domain.User) error
}
```

**Keep interfaces small:**
```go
// BAD — 10-method interface is hard to mock and hard to satisfy
type UserStore interface {
    Get, List, Create, Update, Delete, GetByEmail, GetByToken, ...
}

// GOOD — split by use
type UserReader interface { GetByID(...) }
type UserWriter interface { Create(...); Update(...) }
```

**Rules:**
- Unexported interface in the package that consumes it (only export if used across packages)
- Accept interfaces, return concrete types
- `interface{}` / `any` is a design smell — prefer generics or a concrete type
- Don't create an interface until you have two implementations or need testability

---

## IX. Database & Transactions

### IX.1 Where DB models live

**Use sqlc.** It generates row structs and type-safe query functions from plain SQL. You never write `userRow` by hand — sqlc generates it from your schema and queries. The repository layer maps the generated types to domain entities.

**Without sqlc (manual):** you write row structs with `db` tags, scanning logic, and mappers yourself. This is error-prone and verbose — only do this for dynamic queries sqlc can't handle.

#### IX.1.1 sqlc layout

```
internal/
├── domain/
│   └── user.go              # pure business entity — no DB tags, never changes for DB reasons
├── db/                      # sqlc generated — never edit manually
│   ├── models.go            # row structs (User, Order, ...)
│   ├── querier.go           # generated Querier interface
│   ├── queries.sql.go       # generated query functions
│   └── db.go                # New(), DBTX interface
└── repository/
    └── user_postgres.go     # calls internal/db, maps generated types → domain types
```

**sqlc.yaml** (at service root):
```yaml
version: "2"
sql:
  - engine: postgresql
    queries: internal/db/queries/
    schema:  migrations/
    gen:
      go:
        package:      db
        out:          internal/db
        emit_interface: true
```

**internal/db/queries/users.sql:**
```sql
-- name: GetUser :one
SELECT id, email, name, created_at
FROM users
WHERE id = $1;

-- name: CreateUser :one
INSERT INTO users (id, email, name, created_at)
VALUES ($1, $2, $3, $4)
RETURNING *;

-- name: ListUsers :many
SELECT id, email, name, created_at FROM users
ORDER BY created_at DESC;
```

sqlc generates `internal/db/queries.sql.go` with `GetUser`, `CreateUser`, `ListUsers` functions and a `User` row struct.

**repository/user_postgres.go — calls generated code, maps to domain:**
```go
package repository

import (
    "github.com/org/myservice/internal/db"
    "github.com/org/myservice/internal/domain"
)

type UserPostgres struct {
    q *db.Queries
}

func NewUserPostgres(pool *pgxpool.Pool) *UserPostgres {
    return &UserPostgres{q: db.New(pool)}
}

func (r *UserPostgres) GetByID(ctx context.Context, id string) (*domain.User, error) {
    row, err := r.q.GetUser(ctx, id)
    if errors.Is(err, pgx.ErrNoRows) {
        return nil, fmt.Errorf("get user %s: %w", id, domain.ErrNotFound)
    }
    if err != nil {
        return nil, fmt.Errorf("get user %s: %w", id, err)
    }
    return toUser(row), nil
}

// toUser is the only place that bridges DB schema and domain model
func toUser(r db.User) *domain.User {
    return &domain.User{
        ID:        r.ID,
        Email:     r.Email,
        Name:      r.Name,
        CreatedAt: r.CreatedAt.Time,
    }
}
```

**domain/user.go — unaffected by DB schema:**
```go
package domain

type User struct {
    ID        string
    Email     string
    Name      string
    CreatedAt time.Time
}
```

#### IX.1.2 sqlc vs manual

| | sqlc | Manual pgx/pgxscan |
|---|---|---|
| Row structs | Generated from schema | Written by hand with `db` tags |
| Query functions | Generated, type-safe | Written by hand |
| SQL | Plain `.sql` files | Inline strings |
| Dynamic queries | Not supported — use raw pgx | Supported |
| Schema drift | Caught at `sqlc generate` | Caught at runtime |

Use sqlc for all standard queries. Fall back to raw `pgx` only for queries that are dynamically constructed at runtime (e.g. filter-by-any-field search).

#### IX.1.3 Why domain and DB types are always separate

- DB schema changes (rename a column, split a table) don't touch domain entities or any layer above repository
- Domain entities stay free of `db`, `gorm`, or `json` tags mixed together
- `toUser()` is the single translation point — easy to find, easy to test

### IX.2 Full stack: sqlc → repository → usecase → handler → chi

This traces one request end-to-end so the wiring is explicit. sqlc and chi operate at different layers — they never touch each other directly.

```
chi route → handler → usecase → repository → db.Queries (sqlc) → pgx → PostgreSQL
```

**main.go — compose bottom-up:**
```go
// 1. DB pool
pool, err := pgxpool.New(ctx, cfg.Database.DSN)
if err != nil {
    slog.Error("db connect", "err", err)
    os.Exit(1)
}

// 2. sqlc queries (wraps the pool)
queries := db.New(pool)

// 3. TxManager (for cross-repo transactions)
txm := repository.NewTxManager(pool, queries)

// 4. Repositories — each gets the sqlc Querier
userRepo  := repository.NewUserPostgres(queries)
orderRepo := repository.NewOrderPostgres(queries)

// 5. Usecases
userUC  := usecase.NewUserUsecase(userRepo)
orderUC := usecase.NewOrderUsecase(orderRepo, userRepo, txm)

// 6. Handlers
userH  := handler.NewUserHandler(userUC)
orderH := handler.NewOrderHandler(orderUC)

// 7. Server (chi router lives inside)
srv, err := server.New(cfg.Server,
    &server.Handlers{User: userH, Order: orderH},
    &server.Services{User: rpc.NewUserService(userUC)},
)
```

**repository/user_postgres.go:**
```go
type UserPostgres struct {
    q db.Querier  // interface, not *db.Queries — allows tx override via context
}

func NewUserPostgres(q db.Querier) *UserPostgres {
    return &UserPostgres{q: queriesFromCtx(q)}
}

func (r *UserPostgres) GetByID(ctx context.Context, id string) (*domain.User, error) {
    row, err := r.queries(ctx).GetUser(ctx, id)
    if errors.Is(err, pgx.ErrNoRows) {
        return nil, fmt.Errorf("get user %s: %w", id, domain.ErrNotFound)
    }
    if err != nil {
        return nil, fmt.Errorf("get user %s: %w", id, err)
    }
    return toUser(row), nil
}

// queries returns the tx-bound Querier if a transaction is active, otherwise the default.
func (r *UserPostgres) queries(ctx context.Context) db.Querier {
    if q, ok := ctx.Value(ctxTxQueriesKey).(db.Querier); ok {
        return q
    }
    return r.q
}
```

**handler/user.go — chi URL params, calls usecase:**
```go
type UserHandler struct {
    uc usecase.UserUsecase
}

func NewUserHandler(uc usecase.UserUsecase) *UserHandler {
    return &UserHandler{uc: uc}
}

func (h *UserHandler) Get(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")
    user, err := h.uc.GetUser(r.Context(), id)
    if err != nil {
        handleUsecaseError(w, err)
        return
    }
    respondJSON(w, http.StatusOK, toUserResponse(user))
}
```

### IX.3 Transactions with sqlc

sqlc generates `Queries.WithTx(pgx.Tx)` which returns a new `*Queries` bound to the transaction. The `TxManager` wraps this: it begins a pgx transaction, creates a tx-bound `*Queries`, injects it into context, then commits or rolls back.

```go
// repository/tx.go
type ctxKey struct{}
var ctxTxQueriesKey = ctxKey{}

type TxManager struct {
    pool *pgxpool.Pool
    q    *db.Queries
}

func NewTxManager(pool *pgxpool.Pool, q *db.Queries) *TxManager {
    return &TxManager{pool: pool, q: q}
}

func (tm *TxManager) WithTx(ctx context.Context, fn func(ctx context.Context) error) error {
    tx, err := tm.pool.BeginTx(ctx, pgx.TxOptions{})
    if err != nil {
        return fmt.Errorf("begin tx: %w", err)
    }
    // Inject tx-bound queries so repositories use the same transaction
    ctx = context.WithValue(ctx, ctxTxQueriesKey, tm.q.WithTx(tx))
    if err := fn(ctx); err != nil {
        tx.Rollback(ctx)
        return err
    }
    return tx.Commit(ctx)
}
```

**Usecase — unaware of transactions:**
```go
func (uc *OrderUsecase) PlaceOrder(ctx context.Context, req PlaceOrderRequest) error {
    return uc.txm.WithTx(ctx, func(ctx context.Context) error {
        if err := uc.orderRepo.Create(ctx, req); err != nil {
            return err
        }
        return uc.inventoryRepo.Reserve(ctx, req.ItemID, req.Qty)
    })
}
```

Both `orderRepo.Create` and `inventoryRepo.Reserve` call `r.queries(ctx)` internally — they automatically use the tx-bound `*Queries` from context without knowing a transaction is active.

### IX.4 Connection pool

**Production baseline:**
```go
pool, err := pgxpool.New(ctx, cfg.Database.DSN)

pool.Config().MaxConns = 25
pool.Config().MinConns = 5
pool.Config().MaxConnLifetime = 5 * time.Minute
pool.Config().MaxConnIdleTime = 30 * time.Minute
```

**Rules:**
- Never pass `*pgx.Tx` directly to a repository method signature — propagate via context
- Always set pool limits — pgxpool default is unlimited open connections, which will exhaust PostgreSQL
- Migrations run at deploy time (not startup) — use `golang-migrate` or `goose`
- Repository returns `domain.ErrNotFound` (not `pgx.ErrNoRows`) — translate at the boundary
- Use `pgx` over `database/sql` for PostgreSQL — better performance and native type support

---

## X. Context

### X.1 How many contexts a server uses

A server has exactly three context scopes. Never mix them — each has a different lifetime and owner.

| Scope | Lifetime | Created by | Used for |
|---|---|---|---|
| **Process** | entire process | `main.go` — `signal.NotifyContext` | shutdown signal; passed to infra teardown |
| **Request** | single HTTP request or RPC | framework — `r.Context()` / gRPC handler arg | all I/O inside a handler chain |
| **Operation** | one timed I/O call | handler — `context.WithTimeout(r.Context(), ...)` | external calls that need a tighter deadline than the request |

```go
// main.go — process context, cancelled on SIGINT/SIGTERM
ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
defer stop()

// handler — request context flows in automatically; derive operation context when needed
func (h *UserHandler) Get(w http.ResponseWriter, r *http.Request) {
    // r.Context() is the request context — use it directly for most calls
    user, err := h.userUC.GetUser(r.Context(), chi.URLParam(r, "id"))

    // derive only when this specific call needs a tighter deadline
    ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
    defer cancel()
    result, err := h.externalClient.Fetch(ctx, id)
}

// Shutdown() creates its own short-lived context just for the drain period
func (s *Server) Shutdown(timeout time.Duration) {
    ctx, cancel := context.WithTimeout(context.Background(), timeout)
    defer cancel()
    s.http.Shutdown(ctx)
    s.grpc.GracefulStop()
}
```

**The common mistake — `context.Background()` inside a handler:**
```go
// BAD — disconnects from request cancellation
// if the client disconnects, this DB query keeps running
func (h *UserHandler) Get(w http.ResponseWriter, r *http.Request) {
    user, err := h.repo.GetUser(context.Background(), id)
}

// GOOD — DB query is cancelled when the client disconnects
func (h *UserHandler) Get(w http.ResponseWriter, r *http.Request) {
    user, err := h.repo.GetUser(r.Context(), id)
}
```

`context.Background()` is only valid in `main.go` and in `Shutdown()`. Anywhere else in the request path, always derive from the incoming context.

### X.2 Rules
- First parameter of every function that does I/O: `ctx context.Context`
- Never store a context in a struct — pass it through function calls
- Always check `ctx.Err()` in long loops
- Add values to context only for cross-cutting concerns: request ID, user ID, trace ID

```go
// Adding request ID (in middleware)
ctx = context.WithValue(ctx, ctxKeyRequestID, requestID)

// Retrieving — typed helper prevents key collision
func RequestIDFromCtx(ctx context.Context) string {
    v, _ := ctx.Value(ctxKeyRequestID).(string)
    return v
}
```

---

## XI. internal/server

`internal/server/` owns everything between "we have a wired set of handlers" and "the process is serving traffic." It knows about routing and middleware — nothing else.

### XI.1 File layout

```
internal/server/
├── server.go      # Server struct, Handlers, Services, New(), Start(), Shutdown()
├── http.go        # newHTTPServer() — chi setup, middleware, routes
├── routes.go      # all HTTP route registration
├── middleware.go  # custom HTTP middleware (requestLogger)
└── grpc.go        # newGRPCServer() + interceptors
```

`http.go` and `grpc.go` are symmetric: each owns the construction of its server and all protocol-specific concerns. `server.go` only orchestrates them.

**server.go**

```go
package server

import (
    "context"
    "errors"
    "fmt"
    "net"
    "net/http"
    "time"

    "golang.org/x/sync/errgroup"
    "google.golang.org/grpc"

    "github.com/org/myservice/internal/config"
    "github.com/org/myservice/internal/handler"
    userv1 "github.com/org/myservice/api/proto/user/v1"
)

type Handlers struct {
    User  *handler.UserHandler
    Order *handler.OrderHandler
}

type Services struct {
    User userv1.UserServiceServer
}

type Server struct {
    http            *http.Server
    grpc            *grpc.Server
    grpcLis         net.Listener
    shutdownTimeout time.Duration // needed by the watcher goroutine inside Start
}

func New(cfg config.ServerConfig, h *Handlers, s *Services) (*Server, error) {
    // grpc.Server.Serve() requires a pre-created net.Listener — unlike http.Server which
    // creates its listener internally in ListenAndServe().
    // Binding here (in New, not Start) upholds the constructor contract: New returns a fully
    // initialized Server or fails entirely. If this were in Start(), a *Server could exist
    // with grpcLis=nil, requiring nil checks or risking a panic at Serve time.
    grpcLis, err := net.Listen("tcp", fmt.Sprintf(":%d", cfg.GRPCPort))
    if err != nil {
        return nil, fmt.Errorf("grpc listen: %w", err)
    }
    return &Server{
        http:            newHTTPServer(cfg, h),
        grpc:            newGRPCServer(s),
        grpcLis:         grpcLis,
        shutdownTimeout: cfg.ShutdownTimeout,
    }, nil
}

// Start runs both servers and blocks until both stop. ctx cancellation (e.g. SIGTERM)
// or a failure in either server triggers a graceful shutdown of both.
// Returns nil on clean shutdown, non-nil if a server failed unexpectedly.
func (s *Server) Start(ctx context.Context) error {
    g, gCtx := errgroup.WithContext(ctx)

    g.Go(func() error {
        if err := s.http.ListenAndServe(); !errors.Is(err, http.ErrServerClosed) {
            return fmt.Errorf("http: %w", err)
        }
        return nil
    })
    g.Go(func() error {
        if err := s.grpc.Serve(s.grpcLis); err != nil {
            return fmt.Errorf("grpc: %w", err)
        }
        return nil
    })
    // Watcher: shuts down both servers when either fails or ctx is cancelled.
    // Without this, a healthy server keeps running after the other dies.
    g.Go(func() error {
        <-gCtx.Done()
        s.shutdown()
        return nil
    })

    return g.Wait()
}

func (s *Server) shutdown() {
    ctx, cancel := context.WithTimeout(context.Background(), s.shutdownTimeout)
    defer cancel()
    s.http.Shutdown(ctx)
    s.grpc.GracefulStop()
}
```

**http.go**

```go
package server

import (
    "fmt"
    "net/http"
    "time"

    "github.com/go-chi/chi/v5"
    chimw "github.com/go-chi/chi/v5/middleware"

    "github.com/org/myservice/internal/config"
)

func newHTTPServer(cfg config.ServerConfig, h *Handlers) *http.Server {
    r := chi.NewRouter()
    r.Use(chimw.RequestID)  // injects X-Request-Id header + ctx
    r.Use(chimw.RealIP)     // reads X-Forwarded-For into r.RemoteAddr
    r.Use(chimw.Recoverer)  // catches panics, returns 500
    r.Use(requestLogger)    // structured slog logging (chi's logger isn't slog-aware)
    registerRoutes(r, h)
    return &http.Server{
        Addr:         fmt.Sprintf(":%d", cfg.HTTPPort),
        Handler:      r,
        ReadTimeout:  5 * time.Second,
        WriteTimeout: 10 * time.Second,
        IdleTimeout:  120 * time.Second,
    }
}
```

**routes.go**

All HTTP routes in one file. Group by API version and resource. Scoped middleware (auth) is applied at the group level.

```go
package server

import (
    "github.com/go-chi/chi/v5"

    "github.com/org/myservice/internal/handler"
    "github.com/org/myservice/internal/middleware"
)

func registerRoutes(r chi.Router, h *Handlers) {
    r.Get("/healthz", handler.Healthz)
    r.Get("/readyz",  handler.Readyz)

    r.Route("/api/v1", func(r chi.Router) {
        r.Use(middleware.Authenticate)

        r.Route("/users", func(r chi.Router) {
            r.Post("/",       h.User.Create)
            r.Get("/{id}",    h.User.Get)
            r.Put("/{id}",    h.User.Update)
            r.Delete("/{id}", h.User.Delete)
        })

        r.Route("/orders", func(r chi.Router) {
            r.Post("/",    h.Order.Create)
            r.Get("/{id}", h.Order.Get)
        })
    })
}
```

**middleware.go**

Only custom middleware lives here. Use chi's built-in middleware for everything else.

```go
package server

import (
    "log/slog"
    "net/http"
    "time"

    chimw "github.com/go-chi/chi/v5/middleware"
)

// requestLogger replaces chi's built-in logger which writes plain text, not slog JSON.
func requestLogger(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        start := time.Now()
        ww := chimw.NewWrapResponseWriter(w, r.ProtoMajor)
        next.ServeHTTP(ww, r)
        slog.InfoContext(r.Context(), "request",
            "method",      r.Method,
            "path",        r.URL.Path,
            "status",      ww.Status(),
            "bytes",       ww.BytesWritten(),
            "duration_ms", time.Since(start).Milliseconds(),
            "request_id",  chimw.GetReqID(r.Context()),
        )
    })
}
```

**grpc.go**

```go
package server

import (
    "context"
    "log/slog"
    "time"

    "google.golang.org/grpc"
    "google.golang.org/grpc/codes"
    "google.golang.org/grpc/status"

    userv1 "github.com/org/myservice/api/proto/user/v1"
)

func newGRPCServer(s *Services) *grpc.Server {
    srv := grpc.NewServer(
        grpc.ChainUnaryInterceptor(
            unaryLogger(),
            unaryRecovery(),
        ),
    )
    userv1.RegisterUserServiceServer(srv, s.User)
    return srv
}

func unaryLogger() grpc.UnaryServerInterceptor {
    return func(ctx context.Context, req any, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (any, error) {
        start := time.Now()
        resp, err := handler(ctx, req)
        slog.InfoContext(ctx, "grpc",
            "method",      info.FullMethod,
            "duration_ms", time.Since(start).Milliseconds(),
            "err",         err,
        )
        return resp, err
    }
}

func unaryRecovery() grpc.UnaryServerInterceptor {
    return func(ctx context.Context, req any, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (resp any, err error) {
        defer func() {
            if rec := recover(); rec != nil {
                slog.ErrorContext(ctx, "grpc panic", "panic", rec, "method", info.FullMethod)
                err = status.Errorf(codes.Internal, "internal error")
            }
        }()
        return handler(ctx, req)
    }
}
```

### XI.2 Handler packages — keep HTTP and gRPC separate

```
internal/
├── handler/        # HTTP — one file per resource
│   ├── user.go
│   ├── order.go
│   ├── health.go
│   └── response.go
└── rpc/            # gRPC — one file per proto service
    └── user.go
```

**gRPC service implementation (internal/rpc/user.go):**
```go
package rpc

type UserService struct {
    userv1.UnimplementedUserServiceServer
    uc usecase.UserUsecase
}

func NewUserService(uc usecase.UserUsecase) *UserService { return &UserService{uc: uc} }

func (s *UserService) GetUser(ctx context.Context, req *userv1.GetUserRequest) (*userv1.GetUserResponse, error) {
    user, err := s.uc.GetUser(ctx, req.Id)
    if err != nil {
        return nil, toGRPCError(ctx, err)
    }
    return &userv1.GetUserResponse{User: toProto(user)}, nil
}

// toGRPCError mirrors handleUsecaseError in internal/handler — same domain errors, gRPC status codes
func toGRPCError(ctx context.Context, err error) error {
    switch {
    case errors.Is(err, domain.ErrNotFound):
        return status.Error(codes.NotFound, "not found")
    case errors.Is(err, domain.ErrConflict):
        return status.Error(codes.AlreadyExists, "already exists")
    case errors.Is(err, domain.ErrForbidden):
        return status.Error(codes.PermissionDenied, "forbidden")
    default:
        slog.ErrorContext(ctx, "unhandled rpc error", "err", err)
        return status.Error(codes.Internal, "internal error")
    }
}
```

### XI.3 main.go wiring

```go
srv, err := server.New(cfg.Server,
    &server.Handlers{User: userH, Order: orderH},
    &server.Services{User: rpc.NewUserService(userUC)},
)
if err != nil {
    slog.Error("server init", "err", err)
    os.Exit(1)
}

handler.SetReady(true)

// Start blocks until both servers stop. ctx cancellation (SIGTERM) or a server
// failure triggers graceful shutdown internally — no separate Shutdown call needed.
if err := srv.Start(ctx); err != nil {
    slog.Error("server stopped", "err", err)
    os.Exit(1)
}

// Teardown runs only after both servers have fully drained
db.Close()
shutdownTracer(context.Background())
```

### XI.4 Config

```go
type ServerConfig struct {
    HTTPPort        int           `koanf:"http_port"        validate:"min=1,max=65535"`
    GRPCPort        int           `koanf:"grpc_port"        validate:"min=1,max=65535"`
    ShutdownTimeout time.Duration `koanf:"shutdown_timeout"  validate:"required"`
}
```

### XI.5 Rules

- `server.go` is pure orchestration — it calls `newHTTPServer` and `newGRPCServer`, nothing else
- `http.go` and `grpc.go` are symmetric: each owns its server construction and protocol-specific concerns (middleware vs interceptors)
- `routes.go` is the single source of truth for all HTTP paths — no route definitions anywhere else
- Auth and other scoped middleware attaches at `r.Route()` groups in `routes.go`, not in `http.go`
- `internal/server/` never imports `internal/usecase/` or `internal/repository/` — only `internal/handler/` and `internal/rpc/`
- HTTP and gRPC share the same usecase layer — no duplicate business logic
- Always embed `Unimplemented*Server` in gRPC service structs — forward compatibility when proto adds new methods
- Timeouts are always set on `http.Server` — Go's default is no timeout
- `shutdownTimeout` is the only config value stored in `Server` — it is needed at runtime by the watcher goroutine inside `Start`. All other config values are consumed during `New()` and not stored.
- `Start(ctx)` is blocking and handles its own shutdown via the watcher goroutine — `main.go` does not call a separate `Shutdown()` method

---

## XII. HTTP Handlers

**Handler = decode → validate → call usecase → encode. Nothing else.**

```go
func (h *UserHandler) Get(w http.ResponseWriter, r *http.Request) {
    id := chi.URLParam(r, "id")   // chi URL param — not r.PathValue

    user, err := h.userUC.GetUser(r.Context(), id)
    if err != nil {
        handleUsecaseError(w, err)
        return
    }
    respondJSON(w, http.StatusOK, toUserResponse(user))
}

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

**Shared helpers (internal/handler/response.go):**
```go
func respondJSON(w http.ResponseWriter, status int, v any) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    json.NewEncoder(w).Encode(v)
}

func respondError(w http.ResponseWriter, status int, msg string) {
    respondJSON(w, status, map[string]string{"error": msg})
}
```

**Rules:**
- Use `chi.URLParam(r, "id")` for path parameters — not `r.PathValue`
- Handler never calls repository directly
- Handler never constructs domain entities with business-level defaults — that's usecase responsibility
- One handler file per domain resource (`user_handler.go`, `order_handler.go`)
- Request/response types stay in the handler package — don't bleed into domain

---

## XIII. Concurrency Rules

- **Share memory by communicating** — prefer channels over shared mutable state
- Always pass context to goroutines that should be cancellable
- Use `sync.WaitGroup` to wait for goroutines, not `time.Sleep`
- Use `errgroup` when you need to collect errors from multiple goroutines
- Close channels from the sender, never the receiver
- Protect shared state with `sync.Mutex`; keep critical sections short
- Use `sync.Once` for one-time initialization (e.g., singleton connections)
- Use `sync/atomic` for counters/flags, not a mutex, when the operation is a single read/write

```go
// errgroup for parallel fan-out
g, ctx := errgroup.WithContext(ctx)
for _, id := range ids {
    id := id // capture loop variable (pre-Go 1.22)
    g.Go(func() error {
        return processItem(ctx, id)
    })
}
if err := g.Wait(); err != nil {
    return err
}
```

---

## XIV. cmd/server/main.go

`main.go` is the **composition root**. It knows about all layers, but no layer knows about `main`.

**Responsibilities (in order):**
1. Load and validate config — exit immediately on failure
2. Initialize infrastructure — logger, tracer, DB pool, Redis client
3. Wire dependencies — construct repos → usecases → handlers bottom-up
4. Start the server — delegate to `internal/server`, no inline `http.ListenAndServe`
5. Block on `os.Signal` and drive graceful shutdown

**Hard rules:**
- No business logic in `main.go`
- No route definitions in `main.go`
- No retries, migration runs, or complex startup sequences in `main.go` — those live in `internal/`
- Target: ≤ 80 lines

**Template:**
```go
func main() {
    cfg, err := config.Load()
    if err != nil {
        slog.Error("config", "err", err)
        os.Exit(1)
    }

    shutdown, err := telemetry.Setup(context.Background(), cfg.OTEL)
    if err != nil {
        slog.Error("telemetry", "err", err)
        os.Exit(1)
    }

    db, err := postgres.New(cfg.Database)
    if err != nil {
        slog.Error("db", "err", err)
        os.Exit(1)
    }

    userRepo := repository.NewUserPostgres(db)
    userUC   := usecase.NewUserUsecase(userRepo)
    userH    := handler.NewUserHandler(userUC)

    srv := server.New(cfg, userH)

    ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
    defer stop()

    go srv.Start()
    <-ctx.Done()
    srv.Shutdown(cfg.HTTP.ShutdownTimeout)
    db.Close()
    shutdown(context.Background())
}
```

---

## XV. Infrastructure Init Order

Init order is a dependency graph. Getting it wrong causes **silent** production failures — not crashes.

### XV.1 Dependency graph

```
config
  └── logger          needs: log level from config
        └── tracer    needs: logger for SDK errors; must register global provider BEFORE any client
              ├── db  needs: tracer already registered — pgx otel driver binds at New() time
              └── redis  same — redis otel hooks bind at New() time
                    └── repos → usecases → handlers
                          └── server  nothing accepts traffic until fully wired
```

### XV.2 Why each step must come before the next

| Step | Must come before | Failure if violated |
|---|---|---|
| `config.Load()` | everything | Nothing has valid values |
| `logger` init | everything else | Startup errors go to unstructured stderr — not captured by log aggregator (Loki, Datadog). Silent in prod. |
| `tracer` / OTEL global provider | `postgres.New()`, `redis.New()`, any gRPC client | pgx/redis/grpc otel drivers call `otel.GetTracerProvider()` **at construction time**. If not yet registered, they bind permanently to the no-op provider. DB and cache spans are **silently dropped for the entire process lifetime** — no crash, no warning. |
| `db` connected | `server.Start()` | Cold-start requests hit an uninitialized pool → 500s. Kubernetes marks the pod `Ready` before it actually is. |
| `server.Start()` | signal block | Process exits before serving anything. |

### XV.3 Correct order with annotated template

```go
func main() {
    // 1. Config — everything else depends on values from here
    cfg, err := config.Load()
    if err != nil {
        log.Fatalf("config: %v", err)  // stdlib log — slog not ready yet
    }

    // 2. Logger — must exist before any error can be structured-logged
    logger := telemetry.NewLogger(cfg.App)
    slog.SetDefault(logger)

    // 3. Tracer — register global OTEL provider before ANY instrumented client
    //    pgx/redis/grpc call otel.GetTracerProvider() at New()
    //    if called before this line they permanently bind to the no-op provider
    shutdownTracer, err := telemetry.Setup(context.Background(), cfg.OTEL)
    if err != nil {
        slog.Error("tracer setup failed", "err", err)
        os.Exit(1)
    }

    // 4. DB — after tracer so connection spans are captured
    db, err := postgres.New(cfg.Database)
    if err != nil {
        slog.Error("db connect failed", "err", err)
        os.Exit(1)
    }

    // 5. Redis — after tracer, same reason; less critical than DB
    rdb, err := redis.New(cfg.Redis)
    if err != nil {
        slog.Error("redis connect failed", "err", err)
        os.Exit(1)
    }

    // 6. Wire bottom-up: repos → usecases → handlers
    userRepo := repository.NewUserPostgres(db, rdb)
    userUC   := usecase.NewUserUsecase(userRepo)
    userH    := handler.NewUserHandler(userUC)

    // 7. Server last — no traffic until fully wired
    srv := server.New(cfg, userH)

    ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
    defer stop()

    // 8. Mark ready AFTER full init — readyz probe checks this flag
    handler.SetReady(true)

    go srv.Start()
    <-ctx.Done()

    // 9. Shutdown in REVERSE init order
    srv.Shutdown(cfg.HTTP.ShutdownTimeout)
    rdb.Close()
    db.Close()
    shutdownTracer(context.Background())
}
```

### XV.4 Shutdown must be reverse init order

| Wrong shutdown | Production failure |
|---|---|
| Close DB before server drains | In-flight requests get "conn closed" DB errors |
| Flush traces before DB closes | Last DB spans dropped — latency spikes at shutdown invisible |
| Close Redis before DB | Cache-backed queries fail on requests still processing |

**Correct shutdown sequence:**
```
1. srv.Shutdown(timeout)    — stop intake; wait for in-flight requests to finish
2. rdb.Close()              — close cache
3. db.Close()               — close DB (all queries done)
4. shutdownTracer(ctx)      — flush spans/metrics last
```

### XV.5 Kubernetes readiness probe

Set a `ready` flag only after the full init sequence, and have `/readyz` check it:

```go
// internal/handler/health.go
var ready atomic.Bool

func Readyz(w http.ResponseWriter, r *http.Request) {
    if !ready.Load() {
        http.Error(w, "not ready", http.StatusServiceUnavailable)
        return
    }
    w.WriteHeader(http.StatusOK)
}
```

---

## XVI. Testing

**Pyramid:**
- **Unit** — pure functions, domain logic, usecase with mocked repos: fast, no I/O
- **Integration** — repository layer against a real DB (testcontainers or local Docker)
- **E2E** — HTTP-level tests with `httptest.NewServer`: cover critical paths only

**Usecase unit test pattern:**
```go
type mockUserRepo struct {
    getUserFn func(ctx context.Context, id string) (*domain.User, error)
}
func (m *mockUserRepo) GetByID(ctx context.Context, id string) (*domain.User, error) {
    return m.getUserFn(ctx, id)
}

func TestGetUser_NotFound(t *testing.T) {
    repo := &mockUserRepo{
        getUserFn: func(_ context.Context, _ string) (*domain.User, error) {
            return nil, domain.ErrNotFound
        },
    }
    uc := usecase.NewUserUsecase(repo)
    _, err := uc.GetUser(context.Background(), "nonexistent")
    assert.ErrorIs(t, err, domain.ErrNotFound)
}
```

**HTTP handler test pattern:**
```go
func TestUserHandler_Create(t *testing.T) {
    srv := httptest.NewServer(newRouter(t))
    defer srv.Close()

    body := `{"email":"a@b.com","name":"Alice"}`
    resp, err := http.Post(srv.URL+"/api/v1/users", "application/json", strings.NewReader(body))
    require.NoError(t, err)
    assert.Equal(t, http.StatusCreated, resp.StatusCode)
}
```

**Rules:**
- Table-driven tests for multiple input cases
- `testify/assert` for assertions — not bare `t.Error`
- Never mock the DB in repository tests — use a real DB (testcontainers)
- Test file names: `foo_test.go` same package for white-box, `foo_test` package for black-box
- No `init()` in test files
- `t.Parallel()` on tests that don't share state

---

## XVII. Common Pitfalls

**1. Goroutine leak — no cancellation:**
```go
// BAD
go func() {
    for {
        process()
        time.Sleep(1 * time.Second)
    }
}()

// GOOD
go func() {
    ticker := time.NewTicker(1 * time.Second)
    defer ticker.Stop()
    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            process()
        }
    }
}()
```

**2. Loop variable capture (pre-Go 1.22):**
```go
// BAD
for _, id := range ids {
    go func() { process(id) }() // all goroutines see the same id
}

// GOOD
for _, id := range ids {
    id := id
    go func() { process(id) }()
}
```

**3. Nil map write:**
```go
// BAD — panics
var m map[string]int
m["key"] = 1

// GOOD
m := make(map[string]int)
m["key"] = 1
```

**4. Ignoring context cancellation in a loop:**
```go
// BAD
for _, item := range items {
    process(item)
}

// GOOD
for _, item := range items {
    if err := ctx.Err(); err != nil {
        return err
    }
    process(ctx, item)
}
```

**5. Returning a nil interface vs nil concrete type:**
```go
// BAD — returns non-nil interface wrapping a nil pointer
func getError() error {
    var err *MyError = nil
    return err // caller's `err != nil` is true!
}

// GOOD
func getError() error {
    return nil
}
```

**6. Copying a struct with a mutex:**
```go
// BAD
type Cache struct{ mu sync.Mutex }
func copy(c Cache) { ... } // mutex copied — undefined behavior

// GOOD — always use pointer receiver when struct has a mutex
func (c *Cache) Get(key string) string { ... }
```

**7. Deferred close ignoring error:**
```go
// BAD
defer f.Close()

// GOOD
defer func() {
    if cerr := f.Close(); cerr != nil && err == nil {
        err = cerr
    }
}()
```

**8. HTTP response body not drained before close:**
```go
// GOOD — allows connection reuse
defer func() {
    io.Copy(io.Discard, resp.Body)
    resp.Body.Close()
}()
```
