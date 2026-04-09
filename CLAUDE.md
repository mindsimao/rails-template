# Project: Rails + Hotwire Application

## Tech Stack

- **Framework**: Ruby on Rails 8.1 with Hotwire (Turbo + Stimulus)
- **Database**: PostgreSQL
- **Assets**: Propshaft + Importmap (no Node.js bundler)
- **UI Framework**: Bootstrap 5.3 (CSS via CDN, JS via importmap + jsdelivr CDN)
- **Rendering**: Server-side rendering with Turbo for smooth transitions
- **JavaScript**: Stimulus controllers for interactivity where it adds value
- **Testing**: Minitest (Rails default) — unit, integration, and system tests
- **Linting**: RuboCop with `rubocop-rails-omakase` (37signals/Rails conventions)
- **Security**: Brakeman for static analysis

## Style Guides

Follow the 37signals conventions documented in:

- `docs/37SIGNALS_STYLE.md` — Code style, method ordering, visibility modifiers, CRUD controllers, async patterns
- `docs/CONTROLLER_PATTERNS.md` — Controller/model design patterns, concerns, form objects, association extensions

### Key Conventions

- **CRUD-first controllers**: Model operations as resources, not custom actions. If it doesn't map to CRUD, introduce a new resource.
- **Thin controllers, rich models**: Controllers authenticate, authorize, call 1-2 model methods, render. Business logic lives in models.
- **Model concerns for cohesion**: One concern per domain aspect (e.g., `Card::Closeable`, `Card::Watchable`).
- **No service objects by default**: Use vanilla Rails. Form objects are acceptable for multi-step workflows.
- **Expanded conditionals over guard clauses**: Except early returns at the start of non-trivial methods.
- **Visibility modifier style**: No newline under `private`, indent content beneath it.
- **Method ordering**: class methods, then public (initialize first), then private. Private methods ordered by invocation order.
- **Async convention**: `_later` enqueues a job, `_now` is the synchronous counterpart. Jobs are shallow, delegating to models.
- **Hotwire-first**: Use Turbo Frames and Turbo Streams for dynamic UI. Stimulus only when Turbo isn't enough.

## Commands

```bash
# Linting
bin/rubocop                    # Run RuboCop
bin/rubocop -a                 # Auto-fix safe violations
bin/rubocop -A                 # Auto-fix all violations (including unsafe)

# Security
bin/brakeman                   # Run Brakeman security scan

# Tests
bin/rails test                 # Run all tests
bin/rails test test/models     # Run model tests
bin/rails test test/controllers # Run controller tests
bin/rails test test/integration # Run integration tests
bin/rails test test/system     # Run system tests
bin/rails test path/to/test.rb # Run specific test file
bin/rails test path/to/test.rb:42 # Run specific test at line

# Development
bin/rails server               # Start dev server
bin/rails console              # Rails console
bin/rails db:migrate           # Run migrations
bin/rails db:seed              # Seed database
```

## Agent Workflow & Gates

This project uses 6 specialized agents orchestrated with quality and security gates:

```
Feature Request
  → Planner (design architecture, models, routes)
  → REVIEW GATE: User approves plan
  → Coder (implement following style guides)
  → QUALITY GATE: Reviewer (rubocop -a + style guide compliance)
  → SECURITY GATE: Reviewer (brakeman + security review)
  → PERFORMANCE REVIEW: Reviewer (N+1s, missing indexes, query optimization) [advisory]
  → Tester (write + run minitest tests)
  → Fixer (if issues — max 3 attempts, then escalate to user)
  → FINAL GATE: User sign-off
  → Ready for commit/PR

Bug Fix (TDD mode via Fixer):
  → Write failing test (red)
  → Fix code to pass (green)
  → Verify all tests pass
  → Reviewer gates
```

### Gate Rules

- **No code moves past Quality Gate** without clean RuboCop output (auto-correct applied first)
- **No code moves past Security Gate** without clean Brakeman output
- **Performance Review is advisory** — critical issues (N+1 on high-traffic endpoints) should be fixed, minor ones flagged
- **Fixer must never**: skip tests, use `assert true`, comment out tests, or weaken assertions
- **Fixer escalates to user** after 3 failed fix attempts rather than taking shortcuts
