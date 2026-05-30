# easyBacklog Runtime Compose (v1.0.2)

This release lets you run a private easyBacklog instance using pre-built Docker
images — no code checkout required.

**Release files:**
| File | Purpose |
|------|---------|
| `docker-compose.yml` | Core service definitions (always needed) |
| `setup.sh` | Automated setup script — Linux / macOS |
| `setup.ps1` | Automated setup script — Windows (PowerShell) |

---

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows/macOS) or [Docker Engine](https://docs.docker.com/engine/install/) (Linux)

**Linux only:** After installing Docker, add your user to the `docker` group to
avoid permission errors, then log out and back in:

```bash
sudo usermod -aG docker $USER
# Log out and log back in, then verify:
groups  # should include 'docker'
```

---

## Option A — Automated setup (recommended)

The setup scripts download `docker-compose.yml`, generate a `.env` file with
secure random tokens, pull the images, start all services, wait for the web
server, and initialise the database — all in one step.

**Linux / macOS:**
```bash
curl -fsSL https://github.com/mattanmr/easybacklog/releases/latest/download/setup.sh \
  | bash
```

**Windows (PowerShell):**
```powershell
Invoke-WebRequest `
  -Uri https://github.com/mattanmr/easybacklog/releases/latest/download/setup.ps1 `
  -OutFile setup.ps1
.\setup.ps1
```

The script creates an `easybacklog/` directory in the current folder, keeps all
files together there, and prints the URL and demo credentials when it finishes.

> To skip loading the demo account and sample backlog, add `--skip-sample-data`
> (bash) or `-SkipSampleData` (PowerShell).

---

## Option B — Manual setup (step by step)

Follow these steps if you prefer to understand each action or need to customise
the setup.

### Step 1 — Create a working directory and download `docker-compose.yml`

```bash
mkdir easybacklog
cd easybacklog
```

**Linux / macOS:**
```bash
curl -fsSL \
  https://github.com/mattanmr/easybacklog/releases/latest/download/docker-compose.yml \
  -o docker-compose.yml
```

**Windows (PowerShell):**
```powershell
Invoke-WebRequest `
  -Uri https://github.com/mattanmr/easybacklog/releases/latest/download/docker-compose.yml `
  -OutFile docker-compose.yml
```

> All subsequent commands must be run from inside this `easybacklog/` directory,
> because `docker compose` looks for `docker-compose.yml` in the current folder.

---

### Step 2 — Create a `.env` file

`docker compose` automatically reads a file named `.env` in the same directory
and passes those values to every service. This is how you supply secret tokens
without embedding them in `docker-compose.yml` or your shell history.

Create the file and fill in generated values:

**Linux / macOS:**
```bash
cat > .env <<EOF
SECRET_TOKEN=$(openssl rand -hex 64)
DEVISE_PEPPER=$(openssl rand -hex 64)
DB_PASSWORD=password
EOF
```

**Windows (PowerShell):**
```powershell
$t = -join ((1..64) | ForEach-Object { '{0:x2}' -f (Get-Random -Max 256) })
$p = -join ((1..64) | ForEach-Object { '{0:x2}' -f (Get-Random -Max 256) })
@"
SECRET_TOKEN=$t
DEVISE_PEPPER=$p
DB_PASSWORD=password
"@ | Set-Content .env
```

**What each variable does:**

| Variable | Purpose |
|----------|---------|
| `SECRET_TOKEN` | Rails session secret. Must be ≥30 characters. Changing it after first use invalidates all active sessions. |
| `DEVISE_PEPPER` | Password hashing pepper. Must be ≥30 characters. **Never change this once users have been created** — it would invalidate all passwords. |
| `DB_PASSWORD` | PostgreSQL password. Change to something stronger if the database port will be accessible outside localhost. |

Your `.env` file should look like this (with real random values):

```
SECRET_TOKEN=a3f8c2...
DEVISE_PEPPER=9d1e47...
DB_PASSWORD=password
```

---

### Step 3 — Pull the Docker images

```bash
docker compose pull
```

---

### Step 4 — Start all services

```bash
docker compose up -d
```

This starts four containers: PostgreSQL, Redis, the Rails web server, and the
Sidekiq background worker. Wait about 30–60 seconds for the web server to boot.

---

### Step 5 — Initialise the database (first run only)

```bash
docker compose exec web bundle exec rake db:schema:load
docker compose exec web bundle exec rake db:seed
docker compose exec web bundle exec rake db:seed:sample
```

`db:seed:sample` loads a demo account with a sample backlog. Skip it if you
don't want demo data.

---

### Step 6 — Open the app

Open **http://localhost:3000** in your browser.

Demo credentials (if you ran `db:seed:sample`):
- Email: `demo@example.com`
- Password: `password123`

---

## Persistence

Data is stored in Docker volumes (`postgres_data`, `redis_data`) and survives
container restarts and image updates.

Data is permanently deleted only if you explicitly run:

```bash
docker compose down -v
```

---

## Day-to-day commands

```bash
# Stop all services (data is kept):
docker compose down

# Start again:
docker compose up -d

# Follow web server logs:
docker compose logs -f web

# Open a Rails console:
docker compose exec web bundle exec rails console
```

> If you used the automated setup script, add `-p easybacklog` to every
> `docker compose` command above (e.g. `docker compose -p easybacklog down`),
> because the script names the project `easybacklog` to avoid conflicts.
