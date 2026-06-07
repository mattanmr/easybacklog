# easyBacklog Runtime Compose (v1.0.3)

This release includes a self-contained setup script that downloads everything needed,
starts the application, and walks you through first-time configuration.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows/macOS) or [Docker Engine](https://docs.docker.com/engine/install/) (Linux)

**Linux only:** After installing Docker, add your user to the `docker` group to avoid permission errors, then log out and back in:
```bash
sudo usermod -aG docker $USER
# Log out and log back in, then verify:
groups  # should include 'docker'
```

## Quick Start

Download and run a single script — it checks for Docker, downloads all required files,
starts services, and initialises the database with optional sample data.

**Linux / macOS:**
```bash
curl -fsSL https://github.com/mattanmr/easybacklog/releases/latest/download/manage.sh \
  -o manage.sh && chmod +x manage.sh && ./manage.sh setup
```

**Windows (PowerShell):**
```powershell
Invoke-WebRequest -Uri https://github.com/mattanmr/easybacklog/releases/latest/download/manage.ps1 `
  -OutFile manage.ps1; .\manage.ps1 setup
```

Open the app at http://localhost:3000

Demo credentials (if sample data was loaded):
- Email: `demo@example.com`
- Password: `password123`

## Managing your installation

After setup, use the same script for day-to-day management:

| Command | Description |
|---------|-------------|
| `./manage.sh start` | Start all services |
| `./manage.sh stop` | Stop all services (data is kept) |
| `./manage.sh status` | Show container status |
| `./manage.sh update` | Pull latest images and restart |
| `./manage.sh reset` | Wipe data and reinitialise from scratch |
| `./manage.sh delete` | Remove everything (containers, volumes, files) |

Replace `./manage.sh` with `.\manage.ps1` on Windows.

## Configuration

Settings live in a `.env` file created automatically by `setup`. Open it in any text editor
to customise. Key variables:

| Variable | Default | Purpose |
|----------|---------|---------|
| `SECRET_TOKEN` | demo value | Rails session secret. The setup script offers to generate a secure one. Must be ≥30 characters |
| `DEVISE_PEPPER` | demo value | Password-hashing pepper. Must be ≥30 characters. Do not change after users are created |
| `DB_PASSWORD` | `password` | PostgreSQL password |

After editing `.env`, restart with `./manage.sh start` for changes to take effect.

## Persistence

Data is stored in Docker volumes (`postgres_data`, `redis_data`) and survives restarts.
Your `.env` file preserves settings (including `SECRET_TOKEN`) across restarts, so sessions
are not invalidated.

Data is deleted only when you run `./manage.sh reset` or `./manage.sh delete`.

## Logs

```bash
docker compose logs -f web
```

