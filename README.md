# easyBacklog

An intuitive backlog management tool for Agile practitioners. Originally created by [Matthew O'Riordan](https://mattheworiordan.com) and available at easybacklog.com until September 2022. Now open-sourced under the [MIT license](./LICENSE).

See [CHANGELOG.md](CHANGELOG.md) for details on the Docker containerization and other changes made in this fork.

## Tech Stack

- Ruby on Rails 3.2 / Ruby 2.6.10
- PostgreSQL 11
- Redis 5
- Sidekiq (background jobs)
- jQuery + Backbone.js (frontend)
- Devise (authentication)
- HAML + EJS (templates)

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Git](https://git-scm.com/)

## Setup

```bash
git clone https://github.com/mattanmr/easybacklog.git
cd easybacklog
cp .env.example .env
```

Then set `SECRET_TOKEN` in `.env` with a randomly-generated value.

**Option A — OS-agnostic (uses Docker, already installed):**

```bash
docker run --rm ruby:2.6 ruby -e "require 'securerandom'; puts SecureRandom.hex(64)"
```

Copy the output and paste it after `SECRET_TOKEN=` in your `.env` file.

**Option B — OS-specific one-liners:**

Linux / macOS (Bash):
```bash
sed -i "s/^SECRET_TOKEN=$/SECRET_TOKEN=$(openssl rand -hex 64)/" .env
```

Windows (PowerShell):
```powershell
$token = -join ((1..64) | ForEach-Object { '{0:x2}' -f (Get-Random -Max 256) }); `
  (Get-Content .env) -replace '^SECRET_TOKEN=$', "SECRET_TOKEN=$token" | Set-Content .env
```

If left empty, a token is auto-generated on every container restart — which invalidates all sessions. Setting it once keeps you logged in across restarts.

```bash
docker compose up -d --build
```

Wait ~3-5 minutes for the first build, then initialize the database:

```bash
docker compose exec web bundle exec rake db:schema:load
docker compose exec web bundle exec rake db:seed
```

To also load demo data (a sample user, backlog, themes, and stories):

```bash
docker compose exec web bundle exec rake db:seed:sample
```

Demo credentials: `demo@example.com` / `password123`

Once running, open http://localhost:3000.

### What's Running

| Service    | Description             | Port |
|------------|-------------------------|------|
| Web        | Rails application       | 3000 |
| PostgreSQL | Database                | 5432 |
| Redis      | Cache and job queue     | 6379 |
| Sidekiq    | Background job worker   | —    |

## Common Commands

| Command | Description |
|---------|-------------|
| `docker compose up -d` | Start all services |
| `docker compose down` | Stop all services (keeps data) |
| `docker compose restart` | Restart all services |
| `docker compose logs -f` | Follow logs from all services |
| `docker compose exec web bundle exec rails console` | Open Rails console |
| `docker compose exec web bash` | Shell into the web container |
| `docker compose exec db psql -U postgres -d easybacklog_development` | Open PostgreSQL console |
| `docker compose exec web bundle exec rspec` | Run RSpec tests |
| `docker compose exec web bundle exec cucumber` | Run Cucumber integration tests |
| `docker compose down -v` | Tear down everything (deletes data) |

## Configuration

Copy `.env.example` to `.env` to customize settings (done in setup above).

All external services (SendGrid, Ably, New Relic) are disabled by default. The application works fully offline. See `.env.example` for details on enabling them.

## License

[MIT](./LICENSE)