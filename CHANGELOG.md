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

- **`.env.example`** with documented configuration for all services
- **`docker-compose.override.yml.example`** for optional local customization (port changes, debugging, pgAdmin, etc.)
- **External services control** via `config/initializers/external_services.rb` — all 6 external services (SendGrid, Google Analytics, UserEcho, Ably, Exceptional, New Relic) disabled by default with individual ENV flags to re-enable

## Sample Data

- Added `db/seeds_sample.rb` with a demo user (`demo@example.com` / `password123`), sample account, backlog with 4 themes, 8 user stories, and a sprint
- Available via `docker compose exec web bundle exec rake db:seed:sample`
- Idempotent — safe to run multiple times

## Test Suite

- Implemented 6 RSpec spec files covering functionality, database integrity, frontend integration, external services isolation, and security
- Run with `docker compose exec web bundle exec rspec` (RSpec) or `docker compose exec web bundle exec cucumber` (Cucumber)

## Multi-Architecture Support (2026-04-07)

- Removed PhantomJS and npm from the Dockerfile — PhantomJS was only needed for Poltergeist/Cucumber and was amd64-only
- Removed `platform: linux/amd64` constraints from both dev and release docker-compose files
- Docker images now published as multi-arch manifests (linux/amd64 + linux/arm64)
- Native ARM64 support — no more emulation overhead on Apple Silicon or ARM servers
- Updated README publishing instructions to use `docker buildx` for multi-arch builds

## External Link and Mail Domain Cleanup (2026-04-02)

- Removed remaining hardcoded external easybacklog URLs from runtime-facing views (contact, FAQ, API docs, API access, and top navigation)
- Replaced external API/status/blog references with local/internal routes or local deployment wording
- Updated browser-support and tracking copy to remove hard dependency on easybacklog.com
- Updated mailer footer templates to use helper-driven values instead of hardcoded URLs/emails
- Added helper defaults for local-safe values:
	- `APP_URL` fallback: `http://localhost:3000`
	- `SUPPORT_EMAIL` fallback: `support@localhost.test`
- Updated backend mail and domain defaults to ENV-backed local-safe values:
	- `ADMIN_EMAIL` fallback: `admin@localhost.test`
	- `MAIL_DOMAIN` fallback: `localhost`
	- `MAILER_SENDER` fallback: `robot@localhost.test`
	- `DEFAULT_FROM_EMAIL` fallback: `easyBacklog <no-reply@localhost.test>`
	- `APP_DNS` fallback: `localhost`
	- `FONTS_DOMAIN` fallback: `//#{config.dns}`
- Updated `config/heroku.yml` default `app_url` to `http://localhost:3000`
- Updated demo API helper/spec fixtures from `demo-api@easybacklog.com` to `demo-api@localhost.test`
- Fixed API documentation links to use `api_root_path` (instead of `api_path`) to prevent `No route matches stories#show_without_theme_id` errors on FAQ/contact/auth pages
