# easyBacklog Runtime Compose (v1.0.0)

This release includes a single-file Docker Compose setup for pull-and-run usage.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows/macOS) or [Docker Engine](https://docs.docker.com/engine/install/) (Linux)

**Linux only:** After installing Docker, add your user to the `docker` group to avoid permission errors, then log out and back in:
```bash
sudo usermod -aG docker $USER
# Log out and log back in, then verify:
groups  # should include 'docker'
```

## Download one file

Download `docker-compose.yml` from this release.

## Start on another machine

```bash
docker compose pull
docker compose up -d
```

Open the app at http://localhost:3000

## One-time database initialization (first run only)

```bash
docker compose exec web bundle exec rake db:schema:load
docker compose exec web bundle exec rake db:seed
docker compose exec web bundle exec rake db:seed:sample
```

Demo credentials:
- Email: demo@example.com
- Password: password123

## Configuration (optional)

The app works out of the box with built-in defaults. To customize, set environment variables before running `docker compose up`:

| Variable | Default | Purpose |
|----------|---------|----------|
| `SECRET_TOKEN` | `demo_secret_token` | Rails session secret. Set a unique random value for non-demo use |
| `DEVISE_PEPPER` | `demo_devise_pepper` | Password hashing pepper. Must stay consistent once users are created |
| `DB_PASSWORD` | `password` | PostgreSQL password |

Example (Linux/macOS):
```bash
export SECRET_TOKEN=$(openssl rand -hex 64)
docker compose up -d
```

Example (Windows PowerShell):
```powershell
$env:SECRET_TOKEN = -join ((1..64) | ForEach-Object { '{0:x2}' -f (Get-Random -Max 256) })
docker compose up -d
```

## Persistence

Data is persisted in Docker volumes (`postgres_data`, `redis_data`) and survives restarts.
Data is deleted only if you run:

```bash
docker compose down -v
```

## Stop / logs

```bash
docker compose logs -f web
docker compose down
```
