# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal development workspace and dotfiles repository. It is **not a single project** — three independent sections:

- `projects/` — Template configurations for Git, Gradle, Maven, CMake
- `workspace/` — Personal utilities (C++ competitive programming, Anki, dotfiles, notes)
- `scripts/` — Installation automation scripts for Ubuntu and Rocky Linux

## C++ Competitive Programming (`workspace/cpp/`)

The main tool is the `run` script — a build+test harness for competitive programming.

### Commands

```bash
# Compile and run
workspace/cpp/run program.cpp

# Debug with LLDB
workspace/cpp/run -g program.cpp

# Run against sample test pairs (program-N.in.txt / program-N.out.txt)
workspace/cpp/run -s program.cpp

# Show runtime
workspace/cpp/run -t program.cpp

# Enable INFO logging (-DINFO flag, -O1 optimization)
workspace/cpp/run -i program.cpp
```

### How it works

- Compiler: `g++-14`, standard `-std=c++23`, flags `-Wall -Wextra -Wno-sign-compare`
- Skips recompilation if source is older than binary (flags changes bust cache)
- Warns if TODOs are found in source before compiling
- Sample testing: pairs `*.in.txt` → runs program → diffs against `*.out.txt`; failed output saved to `*.failed.out.txt`
- Debug mode wraps execution in LLDB with LSAN disabled

### Header libraries

- **`debug.h`** — `debug(x)` macro: pretty-prints containers/tuples to stderr with filename, line number, ANSI colors
- **`lc_prelude.h`** — LeetCode I/O: parses bracket notation into `LinkedListNode<T>`/`BinaryTreeNode<T>`, template dispatch from stdin, serializes output back to bracket notation

## Installation Scripts (`scripts/`)

Two OS variants exist for every tool: `scripts/ubuntu/` and `scripts/rocky-linux/`.

```bash
chmod +x scripts/ubuntu/*.sh
./scripts/ubuntu/install-go.sh
./scripts/ubuntu/install-cpp.sh    # installs g++-14
./scripts/ubuntu/install-neovim.sh
# etc.
```

Scripts use `command -v <tool>` to skip already-installed tools and log errors to stderr.

## Project Templates (`projects/`)

- **Gradle**: `gradle build`, `gradle test`, `gradle run` — see `projects/gradle/gradle.properties` for JVM tuning
- **Maven**: `mvn clean install`, `mvn test`, `mvn spring-boot:run` — template targets Spring Boot 3 / Java 17
- **CMake**: `cmake . && make`
- **Git hooks**: activate with `git config --local core.hooksPath .githooks` inside `projects/git/`

## Notes (`workspace/notes/`)

Key references:
- `go-microservice-bootstrap.md` — Production Go service architecture patterns
- `golang-expertise.md` — Go language patterns and idioms reference
- `cp-speed-typing-techniques.md` — Competitive programming techniques

## Conventions

**C++**: `#include <bits/stdc++.h>` + `using namespace std;` is standard here (competitive context). Use `debug(x)` from `debug.h` for dev output. Style follows `.clang-format` (LLVM-based).

**Shell scripts**: `#!/bin/bash`, errors to stderr via `>&2`, ANSI colors for user messages, maintain parity between `ubuntu/` and `rocky-linux/` variants.

**Git**: `.gitignore` excludes `*.out`, `*.pem`, `.env*` (except `.env.example`).
