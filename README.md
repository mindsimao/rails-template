# Rails + Hotwire Template

A Rails 8.1 application template with Devise authentication, Bootstrap 5, and a Claude Code agent workflow.

## Tech Stack

- **Ruby on Rails 8.1** with Hotwire (Turbo + Stimulus)
- **PostgreSQL**
- **Propshaft + Importmap** (no Node.js bundler)
- **Bootstrap 5.3** via dartsass-rails
- **Devise** for authentication (admin-invite-only user management)
- **Claude Code agents** for AI-assisted development

## Getting Started

```bash
# Install dependencies
bundle install

# Set up the database
bin/rails db:create db:migrate db:seed

# Start the dev server
bin/dev
```

## Claude Code Agents

This template includes a full agent workflow in `.claude/`:

- **planner** — design architecture and models
- **coder** — implement following 37signals/Rails conventions
- **reviewer** — RuboCop + Brakeman quality/security gates
- **tester** — write and run Minitest tests
- **fixer** — fix issues (escalates after 3 attempts)
- **scribe** — maintain documentation

See `CLAUDE.md` for full workflow details and `docs/` for style guides.

## Commands

```bash
bin/rubocop -a          # Lint with auto-fix
bin/brakeman            # Security scan
bin/rails test          # Run all tests
bin/dev                 # Start dev server
```
