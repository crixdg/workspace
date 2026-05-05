# Unique ID Generation Techniques

> A practical reference for choosing and implementing unique ID strategies across distributed systems, databases, and applications.

---

## Table of Contents

1. [UUID (Universally Unique Identifier)](#1-uuid-universally-unique-identifier)
2. [Snowflake ID](#2-snowflake-id)
   - [2a. Building a Custom Snowflake Generator](#2a-building-a-custom-snowflake-generator)
   - [2b. Clock Skew — Root Causes and Handling](#2b-clock-skew--root-causes-and-handling)
3. [ULID (Universally Unique Lexicographically Sortable Identifier)](#3-ulid)
4. [NanoID](#4-nanoid)
5. [Database Auto-Increment](#5-database-auto-increment)
6. [Hash-Based IDs](#6-hash-based-ids)
7. [Comparison Table](#7-comparison-table)
8. [Choosing the Right Strategy](#8-choosing-the-right-strategy)

---

## 1. UUID (Universally Unique Identifier)

128-bit identifiers standardized in RFC 4122. Most widely supported.

### Versions

| Version | Method | Use Case |
|---------|--------|----------|
| v1 | Time + MAC address | Sortable, but leaks host info |
| v3 | MD5 hash of namespace + name | Deterministic, reproducible |
| v4 | Random | General purpose, most common |
| v5 | SHA-1 hash of namespace + name | Deterministic, stronger than v3 |
| v7 | Unix timestamp + random (RFC 9562) | Time-sortable, modern replacement for v1 |

### Properties

- **Length**: 36 chars as string (`xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`), 16 bytes binary
- **Collision probability**: Negligible for v4 (~1 in 2^122 per generation)
- **Sortable**: No (v4), Yes (v1, v7)
- **Globally unique**: Yes, without coordination

### Go

```go
import "github.com/google/uuid"

id := uuid.New()         // v4
id := uuid.NewString()   // v4 as string

// v7 (time-sortable, preferred for new systems)
id, err := uuid.NewV7()
```

### PostgreSQL

```sql
-- Native type, stored as 16 bytes
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid()
);

-- UUID v7 (PostgreSQL 17+ or extension)
SELECT gen_random_uuid(); -- v4
```

### Pitfall

UUID v4 as a primary key in B-tree indexes causes page fragmentation due to random insertion order. Prefer UUID v7 or ULID for indexed columns.

---

## 2. Snowflake ID

64-bit integer invented by Twitter. Widely adopted for distributed systems needing sortable, high-throughput IDs.

### Bit Layout (Twitter's original)

```
| 1 bit sign | 41 bits timestamp (ms) | 10 bits machine ID | 12 bits sequence |
```

- **Timestamp**: milliseconds since custom epoch (~69 years of IDs)
- **Machine ID**: up to 1024 nodes
- **Sequence**: up to 4096 IDs per millisecond per node

### Properties

- **Length**: 64-bit integer (fits in `int64`, JavaScript `Number` is unsafe — use string)
- **Sortable**: Yes, roughly time-ordered
- **Globally unique**: Yes, requires unique machine ID per node
- **Throughput**: 4 million IDs/sec per node

### Go

```go
import "github.com/bwmarrin/snowflake"

node, err := snowflake.NewNode(1) // machine ID 1
id := node.Generate()

fmt.Println(id.Int64())  // numeric
fmt.Println(id.String()) // string
fmt.Println(id.Time())   // extract timestamp
```

### Variants

- **Sonyflake**: 63-bit, 10ms resolution, 8-bit sequence, 16-bit machine ID
- **Instagram**: 41-bit ms + 13-bit shard + 10-bit sequence
- **Discord**: 42-bit ms + 10-bit worker + 12-bit process + 12-bit increment

### Pitfall

Clock skew can cause duplicate IDs or backward-time panics. Always handle `time.Now() < lastTimestamp` — either wait or return an error.

---

## 2a. Building a Custom Snowflake Generator

Using a library is fine for most cases. When you need control over bit layout, epoch, or clock-skew policy, implement your own. It is ~100 lines of Go.

### Design decisions before writing code

| Decision | Options | Guidance |
|----------|---------|----------|
| Epoch | Any past UTC timestamp | Pick a recent date — maximizes usable timestamp range. Never use Unix epoch (wastes 50+ years of bits). |
| Timestamp resolution | ms vs. 10ms vs. μs | ms is the standard. μs halves your timestamp range; 10ms gives more sequence headroom. |
| Machine ID source | Env var, last IP octet, DB row, ZooKeeper | Env var is simplest. Must be unique per process — not per host if running multiple replicas. |
| Bit split | sequence vs. machine ID bits | More sequence bits = higher single-node throughput. More machine bits = more nodes. Sum must stay ≤ 22. |
| Clock-skew policy | panic, wait, error, random fallback | See clock skew section below. |

### Reference implementation (Go)

```go
package snowflake

import (
    "errors"
    "fmt"
    "sync"
    "time"
)

const (
    epoch          = int64(1700000000000) // 2023-11-14 UTC — adjust to your deploy date
    machineBits    = 10
    sequenceBits   = 12
    maxMachineID   = -1 ^ (-1 << machineBits)  // 1023
    maxSequence    = -1 ^ (-1 << sequenceBits)  // 4095
    timeShift      = machineBits + sequenceBits  // 22
    machineShift   = sequenceBits               // 12
)

type Generator struct {
    mu          sync.Mutex
    machineID   int64
    sequence    int64
    lastMS      int64
}

func New(machineID int64) (*Generator, error) {
    if machineID < 0 || machineID > maxMachineID {
        return nil, errors.New("machineID out of range")
    }
    return &Generator{machineID: machineID}, nil
}

func (g *Generator) Next() (int64, error) {
    g.mu.Lock()
    defer g.mu.Unlock()

    now := currentMS()

    if now < g.lastMS {
        // Clock moved backward — see clock skew section for full handling options
        return 0, fmt.Errorf("clock moved backward: now=%d last=%d drift=%dms",
            now, g.lastMS, g.lastMS-now)
    }

    if now == g.lastMS {
        g.sequence = (g.sequence + 1) & maxSequence
        if g.sequence == 0 {
            // Sequence exhausted — spin until next millisecond
            now = g.waitNextMS(g.lastMS)
        }
    } else {
        g.sequence = 0
    }

    g.lastMS = now

    id := ((now - epoch) << timeShift) |
        (g.machineID << machineShift) |
        g.sequence

    return id, nil
}

func (g *Generator) waitNextMS(last int64) int64 {
    now := currentMS()
    for now <= last {
        now = currentMS()
    }
    return now
}

func currentMS() int64 {
    return time.Now().UnixMilli()
}
```

### Decoding a Snowflake ID

```go
func Decode(id int64) (ts time.Time, machineID, sequence int64) {
    ms := (id >> timeShift) + epoch
    machineID = (id >> machineShift) & maxMachineID
    sequence = id & maxSequence
    ts = time.UnixMilli(ms).UTC()
    return
}
```

### Machine ID assignment strategies

**Static env var** (simplest)
```bash
MACHINE_ID=42 ./service
```
```go
machineID, _ := strconv.ParseInt(os.Getenv("MACHINE_ID"), 10, 64)
```
Risk: duplicate machine IDs if misconfigured. Use a deployment manifest to enforce uniqueness.

**Last octet of pod IP** (Kubernetes-friendly)
```go
func machineIDFromIP() (int64, error) {
    addrs, err := net.InterfaceAddrs()
    // ... iterate to find a private IP
    parts := strings.Split(ip, ".")
    return strconv.ParseInt(parts[3], 10, 64) // works for /24 subnets
}
```
Breaks if you run more than 256 pods or use non-/24 subnets.

**Atomic DB lease** (safest for large clusters)
```sql
CREATE TABLE machine_id_leases (
    id       SMALLINT PRIMARY KEY,
    hostname TEXT NOT NULL,
    leased_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```
```go
// On startup: INSERT INTO machine_id_leases(id, hostname) VALUES (nextval, hostname)
// On shutdown: DELETE FROM machine_id_leases WHERE hostname = $1
```

---

## 2b. Clock Skew — Root Causes and Handling

Clock skew is the most dangerous failure mode for Snowflake generators. It causes **silent ID duplication** or **generator unavailability** depending on how it is handled.

### What is clock skew?

A Snowflake ID encodes `(timestamp - epoch)` in its high bits. If the system clock goes backward — even by 1ms — the generator may produce an ID with the same timestamp+sequence as a previously issued ID, silently violating uniqueness.

### Root causes

**1. NTP correction (most common)**

NTP (`ntpd`, `chrony`) keeps clocks accurate by slewing (gradually adjusting frequency) or stepping (jumping) the clock. `chrony` slews by default and avoids backward jumps, but `ntpd` with `iburst` or `tinker panic 0` can step the clock backward.

```
Timeline: generator running on Node A
t=1000ms  issued ID: ...01000...0001
t=999ms   NTP steps clock back 1ms   ← skew event
t=999ms   generator: now(999) < last(1000) → DUPLICATE RISK
```

**2. VM live migration / suspend-resume**

When a VM is live-migrated or suspended, the guest clock may freeze while the host clock advances. On resume, the guest clock jumps forward (safe). But if the hypervisor's clock sync overshoots during migration, the guest clock can appear to jump backward relative to the last-seen timestamp in the generator's memory.

**3. Container restart with state loss**

If a generator stores `lastMS` only in memory and the process restarts, it loses that value. On restart, `lastMS = 0`, so all times look "forward." This is safe **unless** the restarted process generates IDs faster than 1ms after the previous process stopped — which is almost always the case. This is not clock skew strictly, but has the same effect: IDs are issued with timestamps that overlap with the previous process run.

**4. Leap second**

POSIX smears leap seconds across a window (Linux default) or repeats the second (older behavior). During smear, `time.Now()` may stall or progress slower than wall time, but rarely goes backward. Low risk in practice.

**5. Distributed system clock disagreement**

Two nodes with unsynchronized clocks may produce IDs with identical `(timestamp, sequence)` if they also share a machine ID. This is a configuration bug (duplicate machine IDs), but clock skew amplifies the window during which it causes duplicates.

### Handling strategies

**Option 1: Return an error (default, safest)**

```go
if now < g.lastMS {
    return 0, fmt.Errorf("clock skew: backward drift of %dms", g.lastMS-now)
}
```
Caller retries with backoff. Correct for most services. Exposes the failure visibly rather than silently producing duplicates.

**Option 2: Wait for clock to catch up (acceptable for small drift)**

```go
if now < g.lastMS {
    drift := g.lastMS - now
    if drift > maxToleratedDriftMS { // e.g., 5ms
        return 0, fmt.Errorf("clock skew too large: %dms", drift)
    }
    // spin until clock catches up
    for now < g.lastMS {
        time.Sleep(time.Millisecond)
        now = currentMS()
    }
}
```
Works well when NTP slewing causes sub-5ms backward steps. Blocks the generator for the duration of drift.

**Option 3: Extend sequence into the skew window (advanced)**

If the sequence bits are not yet exhausted at `lastMS`, increment the sequence and keep emitting. This borrows capacity from the "last known good millisecond" until the clock catches up.

```go
if now < g.lastMS {
    // Use lastMS, increment sequence — we are still issuing unique IDs
    now = g.lastMS
    g.sequence = (g.sequence + 1) & maxSequence
    if g.sequence == 0 {
        return 0, errors.New("sequence exhausted during clock skew")
    }
}
```
Risk: if skew lasts longer than `maxSequence / throughput`, you exhaust the sequence and must still block or error.

**Option 4: Never go backward — always advance lastMS (dangerous)**

```go
if now < g.lastMS {
    now = g.lastMS // pretend time did not go backward
}
```
Silently produces IDs that are out of real time order but still unique within this node. Works if you only need uniqueness, not real-time accuracy. Breaks any downstream system that assumes IDs encode accurate timestamps.

### Defense in depth

1. **Use `chrony` over `ntpd`** — chrony slews by default, avoids backward steps.
2. **Set `makestep` threshold** — `chrony makestep 0.1 3` only allows stepping in the first 3 clock updates.
3. **Monitor clock drift** — expose `clockDriftMS` as a gauge metric; alert if `> 10ms`.
4. **Persist `lastMS` across restarts** — write to a file or Redis on shutdown, load on startup.
5. **Add a startup delay** — sleep 10ms after reading persisted `lastMS` before issuing any IDs.

```go
// On startup, after loading lastMS from storage
time.Sleep(10 * time.Millisecond) // ensure we are past any previously issued timestamps
```

---

## 3. ULID

Universally Unique Lexicographically Sortable Identifier. A modern alternative to UUID.

### Format

```
01ARZ3NDEKTSV4RRFFQ69G5FAV
└──────────┘└────────────────┘
  10 chars       16 chars
  48-bit ms    80-bit random
```

- **Total**: 26 characters, Crockford Base32 encoded
- **Binary**: 128 bits (same size as UUID, interchangeable)

### Properties

- **Sortable**: Yes — lexicographic sort = chronological sort
- **Readable**: Uppercase, no hyphens, URL-safe
- **Monotonic**: Can generate monotonically increasing IDs within the same millisecond
- **Collision**: ~1 in 2^80 within the same millisecond

### Go

```go
import "github.com/oklog/ulid/v2"

id := ulid.Make() // thread-safe, monotonic

// Custom entropy
entropy := ulid.Monotonic(rand.New(rand.NewSource(time.Now().UnixNano())), 0)
id, err := ulid.New(ulid.Timestamp(time.Now()), entropy)
```

### When to prefer over UUID v7

ULID has a more readable string form and broader language support for the original spec. UUID v7 is the IETF standard and has native DB support. Either works — pick based on ecosystem compatibility.

---

## 4. NanoID

URL-friendly, compact random IDs. A modern alternative to UUID v4 for non-database use cases.

### Properties

- **Default length**: 21 characters
- **Alphabet**: `A-Za-z0-9_-` (URL-safe)
- **Collision**: Comparable to UUID v4 at default length
- **Sortable**: No

### Size vs. collision trade-off

| Length | IDs needed for 1% collision probability |
|--------|----------------------------------------|
| 8 | ~800 |
| 12 | ~50,000 |
| 16 | ~3,000,000 |
| 21 | ~149 billion (UUID v4 equivalent) |

### Go

```go
import "github.com/matoous/go-nanoid/v2"

id, err := gonanoid.New()          // 21 chars, default alphabet
id, err := gonanoid.Generate("0123456789abcdef", 16) // custom
```

### Use cases

- Short public-facing IDs (links, tokens, invite codes)
- When you want a UUID-level guarantee with a shorter string
- Not recommended as a primary key in relational DBs (no sort order)

---

## 5. Database Auto-Increment

Sequential integers managed by the database engine.

### Types

| Type | Range | Storage |
|------|-------|---------|
| `INT` / `SERIAL` | ~2 billion | 4 bytes |
| `BIGINT` / `BIGSERIAL` | ~9.2 × 10^18 | 8 bytes |

### PostgreSQL

```sql
-- Modern syntax (PostgreSQL 10+)
CREATE TABLE orders (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY
);

-- Classic
CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY
);
```

### MySQL

```sql
CREATE TABLE orders (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
);
```

### Properties

- **Sortable**: Yes, strictly sequential
- **Globally unique**: No — only within one table/sequence
- **Exposes record count**: Yes (security consideration)
- **Performance**: Excellent — sequential writes = no B-tree fragmentation

### Pitfall

Sequential IDs leak business intelligence (order volume, user count). Use a secondary public-facing ID (NanoID, UUID) for external exposure while keeping the internal integer PK for joins and indexing.

---

## 6. Hash-Based IDs

Deterministic IDs derived from content. Same input always produces the same ID.

### Use cases

- Deduplication (idempotency keys)
- Content-addressable storage (git object IDs)
- Caching keys

### Go

```go
import (
    "crypto/sha256"
    "fmt"
)

func contentID(data []byte) string {
    h := sha256.Sum256(data)
    return fmt.Sprintf("%x", h[:16]) // 32-char hex
}

// For idempotency keys: hash request content
func idempotencyKey(userID, action string, params any) string {
    b, _ := json.Marshal(params)
    input := fmt.Sprintf("%s:%s:%s", userID, action, b)
    h := sha256.Sum256([]byte(input))
    return fmt.Sprintf("%x", h[:])
}
```

### Pitfall

Hash collisions are possible (SHA-256 truncated to 128 bits has ~UUID v4 collision probability). For security-sensitive contexts, use full SHA-256 or SHA-3.

---

## 7. Comparison Table

| Technique | Length | Sortable | Globally Unique | Coordination | Best For |
|-----------|--------|----------|-----------------|--------------|----------|
| UUID v4 | 36 chars | No | Yes | None | General purpose |
| UUID v7 | 36 chars | Yes | Yes | None | DB primary keys |
| ULID | 26 chars | Yes | Yes | None | DB primary keys, readable |
| Snowflake | 18-19 chars | Yes | Yes | Machine ID | High-throughput distributed |
| NanoID (21) | 21 chars | No | Yes | None | Public tokens, URLs |
| Auto-increment | 1-19 chars | Yes | No (per-table) | DB sequence | Internal integer PKs |
| Hash-based | Varies | No | Deterministic | None | Deduplication |

---

## 8. Choosing the Right Strategy

### Decision tree

```
Need globally unique without a DB?
├── Yes → Need time-sorted?
│         ├── Yes → High throughput distributed? → Snowflake
│         │         Otherwise → UUID v7 or ULID
│         └── No  → Short & URL-safe? → NanoID
│                   Otherwise → UUID v4
└── No  → Single DB, internal only? → Auto-increment BIGINT
          Deterministic from content? → Hash-based
```

### Common scenarios

**REST API resource IDs (public)**
- Use UUID v7 or ULID — sortable, no info leakage, no coordination

**Internal join key in a single DB**
- Use `BIGSERIAL` / `BIGINT IDENTITY` — fastest, smallest storage

**Distributed event IDs (Kafka, audit logs)**
- Use Snowflake — time-ordered, 64-bit fits everywhere

**Short invite/share links**
- Use NanoID with length 12–16

**Idempotency keys**
- Use hash of (userID + action + params) — deterministic, no storage needed

**Multi-tenant SaaS, row-level IDs**
- Use UUID v7 — works across shards without coordination

### Storage recommendations

| Format | Postgres | MySQL | Size |
|--------|----------|-------|------|
| UUID | `UUID` native | `CHAR(36)` or `BINARY(16)` | 16 B (binary) |
| ULID | `UUID` (binary-compatible) | `BINARY(16)` | 16 B |
| Snowflake | `BIGINT` | `BIGINT UNSIGNED` | 8 B |
| NanoID | `TEXT` | `VARCHAR(21)` | 21 B |

Always store UUIDs and ULIDs as binary (16 bytes), not as text — 2–3x storage savings and faster index scans.
