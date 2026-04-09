---
description: Run a full code review: Quality Gate (RuboCop + style), Security Gate (Brakeman + manual), and Performance Review.
---

Run a full code review: Quality Gate + Security Gate + Performance Review.

This performs the same checks as the Reviewer agent:

## Pass 1: Quality Gate
1. Run `bin/rubocop -a` — auto-fix what's possible, report remaining offenses.
2. Check changed files against `docs/37SIGNALS_STYLE.md` and `docs/CONTROLLER_PATTERNS.md`:
   - Controllers should be thin (5-20 lines per action, 1-2 model calls)
   - Business logic belongs in models/concerns
   - CRUD-first resources, no custom controller actions
   - Correct method ordering and visibility modifier style
   - Expanded conditionals preferred over guard clauses

## Pass 2: Security Gate
1. Run `bin/brakeman` — report warnings.
2. Manual review of changed files for:
   - SQL injection, XSS, CSRF issues
   - Mass assignment gaps
   - Authentication/authorization holes
   - Sensitive data exposure

## Pass 3: Performance Review (advisory)
1. Check for N+1 queries (associations in loops without eager loading)
2. Missing database indexes (foreign keys, queried columns)
3. Expensive queries (unbounded, count in loops, missing counter caches)
4. Caching opportunities (repeated queries, fragment caching)
5. Turbo/Hotwire performance (unnecessary lazy loads, inline broadcasts)

## Verdict
Report PASS or FAIL for Quality and Security gates. Report performance issues with severity (Critical/Warning/Info). Include specific file:line references for all issues.
