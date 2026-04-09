---
description: Run the test suite (or a specific file/line with optional arguments).
---

Run the test suite.

If arguments are provided, pass them through: `bin/rails test $ARGUMENTS`
Otherwise run the full suite: `bin/rails test`

1. Run the tests and capture output.
2. Report: total tests, assertions, failures, errors, skips.
3. For any failures, show the test name, file:line, and failure message.
4. If all tests pass, confirm with the count.
