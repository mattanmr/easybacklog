# Changelog

Changes made since forking from the original easyBacklog repository.

The original easyBacklog service (easybacklog.com) shut down on September 30, 2022, after serving ~400k backlogs by 55k+ users. The codebase was open-sourced under MIT by its creator, [Matthew O'Riordan](https://mattheworiordan.com). This fork makes it runnable locally via Docker.

## Docker Containerization

The original project could not be built or run — builds hung for 2+ hours due to gem compatibility issues with modern systems.

**What was done:**

- Created a Dockerfile based on Ruby 2.6.10 (last version supporting Rails 3.2 gems) on Debian Bullseye
- Created a docker-compose.yml with four services: PostgreSQL 11, Redis 5, Rails web server, and Sidekiq worker
- Fixed 146+ gem compatibility issues (protocol upgrades from git:// and http:// to https://, version pinning)
- Disabled the `shortly` gem (external URL shortener dependency)
- Pinned `pry-byebug ~> 3.7` and overrode `json ~> 1.8.6` for Ruby 2.6 compatibility
- Chose PostgreSQL 11 specifically (v12+ removed the panic log level required by Rails 3.2)
- Moved database config from `DATABASE_URL` parsing to individual environment variables
- Build time: **2+ hours → ~3 minutes**

## Security Hardening

- Removed hardcoded `SECRET_TOKEN` — now read from environment variable
- Removed hardcoded `DEVISE_PEPPER` — now read from environment variable
- Removed `/raise-error` test endpoint from production routes
- No credentials committed to the repository; all secrets managed via `.env`

## Page Fixes

The original app relied on several external services that are now dead or unreachable:

- Removed broken blog links (blog.easybacklog.com) from header and footer
- Removed Vimeo video embed from the landing page (required internet access)
- Removed Twitter social link from footer
- Replaced external Agile Manifesto link with inline explanation
- Replaced external blog link in preferences with self-contained 50/90 estimation explanation
- Added missing `contact` and `faq` controller actions (pages existed but had no routes)
- Created default locale records so the sign-up language dropdown populates correctly

The application now works fully offline.

## Development Tooling

- **Makefile** with commands for setup, start/stop, logs, console, testing, database operations, and cleanup (`make help` for full list)
- **`.env.example`** with documented configuration for all services
- **`docker-compose.override.yml.example`** for optional local customization (port changes, debugging, pgAdmin, etc.)
- **External services control** via `config/initializers/external_services.rb` — all 6 external services (SendGrid, Google Analytics, UserEcho, Ably, Exceptional, New Relic) disabled by default with individual ENV flags to re-enable

## Sample Data

- Added `db/seeds_sample.rb` with a demo user (`demo@example.com` / `password123`), sample account, backlog with 4 themes, 8 user stories, and a sprint
- Available via `make db-seed-sample` or `make setup-with-sample`
- Idempotent — safe to run multiple times

## Test Suite

- Implemented 6 RSpec spec files covering functionality, database integrity, frontend integration, external services isolation, and security
- Run with `make test` (RSpec) or `make test-cucumber` (Cucumber integration tests)
