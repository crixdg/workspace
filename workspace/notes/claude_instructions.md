# How to Write a Perfect CLAUDE.md

A CLAUDE.md file is the first thing Claude reads when entering your project. It replaces the need to re-explain the codebase, conventions, and constraints every session. A great one makes Claude immediately effective. A poor one (or missing one) means Claude infers everything from scratch and makes guesses that don't match your team's standards.

This document tells you exactly what to put in CLAUDE.md, what to skip, and how to adapt it for every major project type.

---

## What CLAUDE.md Actually Does

Claude loads CLAUDE.md at the start of every session. It uses it to:

- Understand the project's purpose, tech stack, and architecture
- Know which commands to run (build, test, lint, migrate)
- Follow your team's conventions without being told each time
- Avoid making changes that break unstated rules (e.g., "don't mock the DB")
- Know what it's allowed to do autonomously vs. what needs confirmation

Think of it as onboarding documentation written specifically for Claude — not for humans. Humans read README. Claude reads CLAUDE.md.

---

## The Universal Structure

Every CLAUDE.md, regardless of project type, should follow this shape. Sections marked **[required]** belong in every project. Sections marked **[if applicable]** are included only when relevant.

```
1.  Project identity                  [required]
2.  Quick start                       [required]
3.  Repository layout                 [required]
4.  Development setup                 [required]
5.  Key commands                      [required]
6.  Architecture and constraints      [required]
7.  Coding conventions                [required]
8.  Testing conventions               [required]
9.  Error handling approach           [required]
10. Database / migrations             [if applicable]
11. API contracts                     [if applicable]
12. Authentication / security         [if applicable]
13. Observability (logs/traces)       [if applicable]
14. Infrastructure / deployment       [if applicable]
15. Collaboration and PR rules        [if applicable]
16. What NOT to do                    [required]
17. Context for Claude specifically   [required]
```

---

## Section-by-Section Guide

### 1. Project Identity

One paragraph. Answer: what does this system do, who uses it, and what does it own?

```markdown
## Project

`payment-service` processes card payments and manages transaction records for the
Acme platform. It is the authoritative source for payment state. Other services
query it via gRPC; it never calls them.
```

What to avoid:

- Marketing language ("industry-leading", "best-in-class")
- Vague descriptions ("a backend service")
- History or context that doesn't affect how code is written

---

### 2. Quick Start

A ranked list of 4–6 files or directories Claude should read first. This saves Claude from exploring blindly.

```markdown
## Quick start

Read these before making any changes:

1. `cmd/server/main.go` — wiring root; shows every dependency
2. `internal/domain/` — core types and invariants; never bypass
3. `config/config.go` — all env vars in one place
4. `api/openapi/v1.yaml` — the HTTP contract; update before changing handlers
5. `Makefile` — all canonical commands
```

---

### 3. Repository Layout

A tree with one-line annotations. Don't annotate obvious names (`README.md`, `.gitignore`). Annotate every non-obvious directory and key files that have rules attached to them.

```markdown
## Repository layout

src/
├── cmd/server/ # binary entry point — keep under 50 lines
├── internal/
│ ├── domain/ # entities, errors, repository interfaces — zero framework imports
│ ├── service/ # business logic — no HTTP/DB imports
│ ├── handler/ # HTTP: parse → call service → respond (no logic here)
│ └── repository/ # DB implementations of domain interfaces
├── migrations/ # SQL files — never edit merged ones, always add new
├── pkg/ # code safe to import from other services
└── api/openapi/ # OpenAPI spec — source of truth for HTTP API
```

---

### 4. Development Setup

Exact commands, in order, to go from a fresh clone to a running service. Include prerequisites. Don't assume anything.

````markdown
## Development setup

Prerequisites: Go 1.24+, Docker, `make`

```bash
cp .env.example .env         # fill in secrets
make infra-up                # start postgres + redis
make migrate                 # apply all migrations
make run                     # start server with live reload (air)
```
````

Required env vars are documented in `.env.example`. The service will panic on startup
if any required var is missing — this is intentional.

---

### 5. Key Commands

A reference table. Include every command a developer (or Claude) might need to run.

```markdown
## Key commands

| Command                 | Action                                  |
| ----------------------- | --------------------------------------- |
| `make run`              | Start server with live reload           |
| `make test`             | Unit tests                              |
| `make test-integration` | Integration tests (requires running DB) |
| `make lint`             | golangci-lint                           |
| `make gen`              | Regenerate mocks and protobuf           |
| `make migrate`          | Apply pending migrations                |
| `make migrate-down`     | Roll back one migration                 |
| `make build`            | Compile to `bin/server`                 |
```

---

### 6. Architecture and Constraints

Should answer:

- What exists:
  - What are the major components/layers? (e.g., HTTP handlers → service layer → repository → DB)
  - What external systems does this connect to? (databases, caches, queues, external APIs)
  - What communication protocols are used? (REST, gRPC, events)

- How it fits together
  - How do requests flow through the system end-to-end?
  - What owns what? (which layer is responsible for validation, business logic, persistence)
  - How are dependencies wired? (dependency injection pattern, wire/fx/manual)

- Where to find things
  - Which package/directory contains which concern?
  - Where do domain types live vs. transport types vs. persistence types?

- Key decisions
  - Why was a specific pattern chosen? (e.g., "repository pattern because we may swap datastores")
  - Any non-obvious constraints? (e.g., "all DB access must go through the repo layer, never raw queries in handlers")

```markdown
## Architecture

Dependency direction (strict — never skip layers):
```

handler → service → domain ← repository implementation

```

Rules:
- `internal/domain/` has zero framework or DB imports. Ever.
- `internal/service/` has zero HTTP or DB imports.
- Handlers contain no business logic — delegate everything to a service method.
- Repository interfaces are defined in `internal/domain/`, not in `internal/repository/`.
- `pkg/` is imported by other services — breaking changes require a deprecation cycle.
```

---

### 7. Coding Conventions

Only write things Claude cannot infer from reading the existing code. Skip "use 4 spaces" (Claude can see that). Write things that are surprising, non-obvious, or the result of a past decision.

```markdown
## Conventions

- Use typed string aliases for all IDs (`type UserID string`) — never bare `string`.
- Repository interfaces are small and split: `AccountReader` + `AccountWriter`.
- Functional options pattern for any constructor with more than 3 optional params.
- `errors.Is` / `errors.As` always — never string matching on error messages.
- Domain errors are exported sentinel `var Err...` values in `internal/domain/`.
- No `utils/`, `helpers/`, or `common/` packages — name by what the package provides.
```

---

### 8. Testing Conventions

Explain the testing philosophy, not just "write tests". Include: what to mock, what not to mock, build tags, where tests live, and any non-obvious tooling.

```markdown
## Testing

- Unit tests: `*_test.go` beside the source file, no build tag.
- Integration tests: `*_integration_test.go` with `//go:build integration`.
- Never mock the database in integration tests — use testcontainers for a real DB.
- Mock only at interface boundaries using mockery-generated mocks.
- Use `require` for fatal assertions, `assert` for non-fatal (testify).
- All tests run with `-race`. CI will fail without it.
- `make test` runs unit only. `make test-integration` runs integration.
```

---

### 9. Error Handling Approach

Describe the project's specific error strategy. This varies enormously between teams.

```markdown
## Error handling

- Wrap errors with context at every layer boundary: `fmt.Errorf("create account: %w", err)`.
- DB-layer translates driver errors to domain errors (e.g., `pgx.ErrNoRows` → `ErrNotFound`).
- Service layer returns domain errors — never HTTP status codes or driver errors.
- Handler layer maps domain errors to HTTP responses via a single `mapError()` function.
- Never log and return. Log once at the top level (server error handler). Return below.
- `panic` is only for programmer errors at startup (bad config). Never in request path.
```

---

### 10. Database / Migrations

Include only if the project has a database.

```markdown
## Database

- ORM: none — raw SQL with pgx v5.
- Migrations: goose. Files in `migrations/NNN_description.{up,down}.sql`.
- Never edit a migration that has been merged to `main` — add a new one.
- Every migration must have a `down` file.
- Run in production via `make migrate` as a pre-deploy step — not embedded in the server binary.
- Connection pooling config is in `config/config.go` — do not hardcode pool sizes elsewhere.
```

---

### 11. API Contracts

Describe where the contract lives and what owns it.

```markdown
## API

- REST: `api/openapi/v1.yaml` is the source of truth. Update it before changing handler signatures.
- gRPC: `api/proto/v1/*.proto`. Update before changing gRPC methods. Run `make gen` after.
- Response envelope: `{ "data": ... }` for success, `{ "error": { "code": "...", "message": "..." } }` for errors.
- Pagination: cursor-based. `next_cursor` in the response meta.
- Breaking changes to the public API require a version bump (`/v2/`).
```

---

### 12. Authentication / Security

```markdown
## Security

- Secrets only from env vars — never committed or hardcoded.
- Auth middleware applied explicitly to every protected route group.
- SQL uses parameterized queries only — never string interpolation.
- Passwords: bcrypt with cost 12 minimum.
- Sensitive fields (passwords, tokens) must never appear in logs.
- `govulncheck` runs in CI — fix HIGH/CRITICAL before merging.
```

---

### 13. Observability

```markdown
## Observability

- Logging: stdlib `slog`, JSON in production. Always use `slog.XxxContext` to propagate trace IDs.
- Tracing: OpenTelemetry. Every service method and repository call gets a span.
- Metrics: Prometheus. Exposed on `:9090/metrics` (internal port only, not public).
- Never log PII (email, name, phone) in production — use account ID instead.
```

---

### 14. What NOT To Do

One of the most valuable sections. List specific things Claude might do that would be wrong for this project.

```markdown
## Do not

- Do not add `utils.go` or catch-all helper files.
- Do not call `os.Exit` outside of `main.go`.
- Do not use `http.DefaultClient` — always create a client with a timeout.
- Do not use `interface{}` or `any` in new code — use generics or concrete types.
- Do not edit generated files (`*.pb.go`, `mocks/`) — regenerate with `make gen`.
- Do not add business logic to handlers — move it to the service layer.
- Do not skip the `down` migration when writing a new migration.
- Do not use `time.Sleep` in non-test code.
- Do not commit `.env` files.
```

---

### 15. Context for Claude Specifically

Optional but powerful. Tell Claude things it needs to know about how you want it to work in this codebase — autonomy level, what to confirm before doing, known gotchas.

```markdown
## Working with Claude

- You may edit any file in `internal/` freely.
- Always ask before changing `pkg/` — it's imported by other services.
- Always ask before modifying database migrations that already exist.
- When adding a new feature, follow the existing pattern in the nearest similar feature.
- When unsure about a naming decision, check the patterns in `internal/domain/`.
- Do not create new packages without flagging it — discuss placement first.
```

---

## Per-Project-Type Templates

### Go Backend / Microservice

Focus on:

- Layer diagram (handler → service → domain ← repo)
- Where repository interfaces live (in domain, not in repo package)
- Migration tool and rules
- `internal/` vs `pkg/` boundary

Key "Do not" items:

- No `utils` packages
- No business logic in handlers
- No mocking the DB in integration tests
- No `http.DefaultClient`

Minimum sections: all 17.

---

### TypeScript / Node.js API (Express, Fastify, NestJS)

Focus on:

- Module system (ESM vs CommonJS — pick one, state it)
- Folder structure (feature-based vs layer-based)
- ORM conventions (Prisma schema location, TypeORM entity rules)
- Strict TypeScript settings (`tsconfig.json` notable flags)
- Import aliases and path mappings

Key "Do not" items:

- Do not use `any` — use `unknown` and narrow
- Do not import across feature module boundaries directly
- Do not mutate request/response objects in middleware — use locals

Minimum sections: 1–10, 14, 15.

---

### Python FastAPI / Django

Focus on:

- Virtual env / dependency tool (uv, poetry, pip — pick one)
- Pydantic model location and validation rules
- Alembic migration conventions
- Async vs sync boundaries (FastAPI: be explicit about which endpoints are async and why)
- Type annotations: required everywhere or enforced by mypy

Key "Do not" items:

- Do not use bare `except:` — catch specific exceptions
- Do not import from `settings` inside model files (circular import)
- Do not use mutable default arguments
- Do not bypass Pydantic validation with `model.field = value` after construction

Minimum sections: 1–10, 14, 15.

---

### React / Next.js Frontend

Focus on:

- Component organization (by feature, by type, or colocation)
- State management rules (where global state lives, what stays local)
- Data fetching layer (React Query, SWR, server components — which and where)
- CSS approach (Tailwind classes, CSS modules, styled-components)
- When to use Server Components vs Client Components (Next.js App Router)

Key "Do not" items:

- Do not lift state higher than needed
- Do not fetch data inside components that aren't responsible for data ownership
- Do not use `useEffect` for derived state — compute it during render
- Do not add `'use client'` to shared UI components — keep them server-compatible

Minimum sections: 1–9, 14, 15.

---

### Mobile — React Native / Flutter

Focus on:

- Navigation library and route definition location
- Platform-specific code conventions (`*.ios.ts`, `*.android.ts`)
- State management boundaries
- Native module rules (when to write a bridge vs use a library)
- Build and release commands per platform

Key "Do not" items:

- Do not hardcode platform checks in shared components
- Do not use inline styles for anything reused — use a stylesheet
- Do not run network requests without offline fallback handling

---

### Monorepo (Turborepo / Nx / Bazel)

Focus on:

- Package/app naming conventions
- Inter-package import rules (which packages can import which)
- Where shared types/utilities live
- How to run commands (workspace-level vs package-level)
- Caching rules — which tasks are cacheable

Key "Do not" items:

- Do not add direct imports between apps (only through shared packages)
- Do not add shared logic directly into an app — extract to a package first
- Do not run `npm install` in a sub-package — always from the root

---

### CLI Tool (Go / Python / Node)

Focus on:

- Command structure (subcommand pattern, cobra/click/yargs conventions)
- Configuration file location and precedence (flags > env > config file > defaults)
- Exit codes and what each means
- Output format conventions (plain text, JSON with `--json` flag, colors)

Key "Do not" items:

- Do not write to stdout for anything that isn't command output (use stderr for logs)
- Do not use `os.Exit` inside library functions — only in `main`
- Do not break existing flag names — they are a public API

---

### Data Pipeline / ML System

Focus on:

- Data schema ownership and validation approach
- Idempotency rules (pipelines must be re-runnable without side effects)
- Partitioning and file format conventions
- How models are versioned and loaded
- What constitutes a "breaking" data change

Key "Do not" items:

- Do not hardcode file paths — use config/env
- Do not load an entire dataset into memory — use streaming
- Do not skip data validation at pipeline boundaries

---

## Common Mistakes in CLAUDE.md Files

| Mistake                                                 | Why it's a problem                           | Fix                                                     |
| ------------------------------------------------------- | -------------------------------------------- | ------------------------------------------------------- |
| Describing how code works instead of what the rules are | Claude can read the code; it needs the rules | Write constraints, not explanations                     |
| Documenting what the code does today                    | It goes stale within days                    | Document conventions and constraints, not current state |
| Including everything                                    | Claude can't prioritize                      | Cut ruthlessly — less is more                           |
| Missing the "Do not" section                            | Claude will make plausible but wrong choices | Always include explicit prohibitions                    |
| Using vague language ("follow best practices")          | Means nothing to Claude or humans            | Be specific: "use pgx v5, not database/sql"             |
| No "quick orientation" list                             | Claude wastes time exploring                 | List the 5 files that matter most                       |
| No commands table                                       | Claude guesses or asks every time            | List every make/script/CLI command                      |
| Treating CLAUDE.md as a README                          | Different audiences, different needs         | README = humans, CLAUDE.md = Claude                     |

---

## Quality Checklist

Before considering your CLAUDE.md complete, verify:

- [ ] A new person (or Claude) can get the service running from the dev setup section alone
- [ ] The architecture section explains layer rules, not just layer names
- [ ] The "Do not" section has at least 5 specific, actionable items
- [ ] Key commands covers build, test, lint, and migrate
- [ ] Every significant non-obvious convention has a brief "why" inline
- [ ] No section is longer than it needs to be — cut aggressively
- [ ] The file is under 300 lines total (beyond that, Claude's attention dilutes)
- [ ] You've included the repo layout with annotations, not just names
- [ ] Sensitive data, secrets, and URLs are not present
- [ ] Someone reviewed it on behalf of Claude: "Would this prevent the top 10 wrong moves?"

---

## Length and Tone

**Target length:** 150–300 lines. Under 150 is usually too sparse. Over 400 is usually noise.

**Tone:**

- Direct, imperative voice: "Use X", "Never Y", "Always Z"
- No filler ("it is important to note that...")
- No hedging ("you may want to consider...")
- No history ("we used to use X but now we use Y because...")

**Format:**

- Use code blocks for commands and file paths
- Use tables for reference material (commands, env vars)
- Use bullet lists for rules
- Use short paragraphs for explanations
- No emoji unless your team uses them everywhere already

---

## Maintenance

CLAUDE.md rots if nobody owns it. Rules:

- Update it when a convention changes — before merging the PR that changes the convention.
- Review it quarterly as a team — "is this still accurate?"
- When Claude makes a systematic wrong choice, ask: "should this be in CLAUDE.md?"
- When onboarding a new developer reveals a gap, add it to CLAUDE.md (not just the wiki).

The best CLAUDE.md files grow from real incidents: "Claude did X, which was wrong because Y — add Y to CLAUDE.md."
