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

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows/macOS) or [Docker Engine](https://docs.docker.com/engine/install/) (Linux)
- [Git](https://git-scm.com/)

**Linux only:** After installing Docker, add your user to the `docker` group to avoid permission errors, then log out and back in:
```bash
sudo usermod -aG docker $USER
# Log out and log back in, then verify:
groups  # should include 'docker'
```

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

## Standalone Release (Pull & Run)

A standalone `docker-compose.yml` in `releases/` lets anyone run easyBacklog without cloning the repo. It pulls pre-built images from Docker Hub. See [RELEASE_NOTES_RUNTIME.md](RELEASE_NOTES_RUNTIME.md) for end-user instructions.

### Publishing a New Release

1. Make your code changes and commit them.
2. Create a multi-arch buildx builder (one-time setup):
   ```bash
   docker buildx create --name multiarch --use
   ```
3. Build and push multi-arch images (amd64 + arm64):
   ```bash
   docker buildx build --platform linux/amd64,linux/arm64 \
     --tag mattanmr/easybacklog-web:v1.0.3 \
     --tag mattanmr/easybacklog-web:latest --push .
   docker buildx build --platform linux/amd64,linux/arm64 \
     --tag mattanmr/easybacklog-sidekiq:v1.0.3 \
     --tag mattanmr/easybacklog-sidekiq:latest --push .
   ```
4. Verify the manifests include both platforms:
   ```bash
   docker buildx imagetools inspect mattanmr/easybacklog-web:v1.0.2
   docker buildx imagetools inspect mattanmr/easybacklog-sidekiq:v1.0.2
   ```
3. Run the release E2E test to validate:
   ```powershell
   .\scripts\test-release-compose.ps1
   ```
4. If all 28 tests pass, the release is good. Commit and push.

### Release E2E Test

`scripts/test-release-compose.ps1` simulates an end-user experience from scratch:

- Copies the release compose file to an isolated temp directory
- Pulls images from Docker Hub, starts all services
- Initializes the database (schema, seeds, sample data)
- Runs smoke tests (home page, health endpoint)
- Tests authentication (sign in, session, dashboard)
- Tests API CRUD (list, create, read, delete backlogs)
- Verifies Sidekiq is running and connected to Redis
- Tests data persistence across a full restart

The script uses an isolated Docker Compose project name (`easybacklog-release-test`) so it never interferes with the development environment.

Use `-SkipCleanup` to keep containers running after the test for debugging:
```powershell
.\scripts\test-release-compose.ps1 -SkipCleanup
```

## License

[MIT](./LICENSE)