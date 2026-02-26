# Quick Start Guide: Running easyBacklog with Docker

Get easyBacklog running on your machine in minutes—no cloning, no building required.

## What is easyBacklog?

easyBacklog is an intuitive backlog management tool for Agile practitioners. The service shut down in September 2022, but the source code is now open source (MIT license) and pre-built Docker images are available for you to run locally.

## Prerequisites

- **Docker** and **Docker Compose** installed on your machine
  - [Docker Desktop](https://www.docker.com/products/docker-desktop) (includes both)
- ~2GB free disk space for the Docker image and database
- Internet connection (to download the image first time)

## Quick Start (3 Steps)

### 1. Create a Project Directory

```bash
mkdir easybacklog && cd easybacklog
```

### 2. Set Up Configuration Files

Download or create the required files:

**Option A: Using curl (simplest)**

```bash
curl -o docker-compose.yml https://raw.githubusercontent.com/mattanmr/easybacklog/main/docker-compose.example.yml
curl -o .env https://raw.githubusercontent.com/mattanmr/easybacklog/main/.env.example
```

**Option B: Manual Setup**

Create two files in your `easybacklog` directory:

**`docker-compose.yml`** — Copy from the [repository's docker-compose.example.yml](docker-compose.example.yml)

**`.env`** — Copy from the [repository's .env.example](.env.example)

### 3. Start the Application

```bash
docker-compose up
```

Docker will:
- Pull the pre-built easyBacklog image from Docker Hub
- Start PostgreSQL and Redis services
- Initialize the database
- Start the Sidekiq background job processor

First run takes ~1-2 minutes (image download + database setup). Subsequent runs are much faster.

### 4. Access the Application

Open your browser:

```
http://localhost:3000
```

**Default Test Credentials:**
- Email: `user@example.com`
- Password: `password`

You're done! Start creating backlogs.

## Stopping the Application

To pause the services (keeps data):

```bash
docker-compose down
```

To stop and remove all data (clean slate on next start):

```bash
docker-compose down -v
```

## Configuration

### Using Custom Docker Image

By default, the compose file uses `mattanmr/easybacklog:latest`. To use a different image:

```bash
# Use a specific version
export DOCKER_IMAGE=mattanmr/easybacklog:v1.0.0
docker-compose up

# Or modify docker-compose.yml:
# Change: image: ${DOCKER_IMAGE:-mattanmr/easybacklog:latest}
# To: image: myname/myimage:tag
```

### Database Configuration

Edit `.env` to customize database settings:

```bash
DB_PASSWORD=my_secure_password    # Change database password
DB_HOST=db                        # Docker service name (usually don't change)
RAILS_ENV=development             # Keep as development
```

**⚠️ Important:** If you change `DB_PASSWORD` after first run, reset the database:

```bash
docker-compose down -v
docker-compose up
```

### Port Configuration

By default, easyBacklog runs on port 3000. To use a different port:

Edit `docker-compose.yml` and change:

```yaml
web:
  ports:
    - "3001:3000"  # Access at http://localhost:3001 instead
```

Or use environment variable:

```bash
export WEB_PORT=3001
docker-compose up
```

## Viewing Application Logs

See what's happening in real-time:

```bash
# All services
docker-compose logs -f

# Just the web app
docker-compose logs -f web

# Just background jobs
docker-compose logs -f sidekiq

# Follow last 50 lines
docker-compose logs --tail=50 -f web
```

## Troubleshooting

### Port Already in Use

If port 3000, 5432, or 6379 is already in use on your machine, change it in `docker-compose.yml`:

```yaml
web:
  ports:
    - "3001:3000"      # Use 3001 instead of 3000

db:
  ports:
    - "5433:5432"      # Use 5433 instead of 5432

redis:
  ports:
    - "6380:6379"      # Use 6380 instead of 6379
```

Or see [Port Configuration](#port-configuration) section above.

### Database Connection Errors

```
ERROR: could not connect to server: Connection refused
```

PostgreSQL is still initializing. Check status:

```bash
docker-compose ps
```

The `db` service should show `healthy`. Wait 10-15 seconds if it shows `starting`, then try again.

### Image Download Failed

If the image won't download:

```bash
# Try again - Docker will resume
docker-compose up

# Or manually pull (troubleshoot)
docker pull mattanmr/easybacklog:latest

# Check Docker storage space
docker system df
```

Needs ~1.5GB free space for the image.

### Docker Resource Issues

If containers crash or freeze:

```bash
# Increase Docker memory in Docker Desktop:
# Settings → Resources → Memory: Set to 4GB or more

# Or check current usage
docker stats

# Restart Docker
docker-compose restart
```

### "Invalid digest" Password Errors

If seeing authentication errors:

```bash
docker-compose down -v
docker-compose up
```

This resets the database with fresh credentials.

### Container Won't Start

```bash
# Check detailed error
docker-compose logs web

# Try rebuilding the container
docker-compose up --force-recreate

# Or restart everything
docker-compose restart
```

## Creating User Accounts

### Via Web Interface (Recommended)

1. Go to http://localhost:3000
2. Click **Sign up**
3. Enter email, name, and password
4. Create your first backlog!

### Using Docker Exec

For advanced users, create a user from the command line:

```bash
docker-compose exec web bundle exec rails console <<'EOF'
User.create!(
  name: "Demo User",
  email: "demo@example.com",
  password: "password123",
  password_confirmation: "password123"
)
puts "User created!"
exit
EOF
```

## Database Backup & Reset

### Backup Your Data

PostgreSQL data is stored in the `postgres_data` volume. To backup:

```bash
# Export database
docker-compose exec db pg_dump -U postgres easybacklog_development > backup.sql

# Or backup the Docker volume
docker run --rm -v easybacklog_postgres_data:/data -v $(pwd):/backup \
  postgres:11 tar czf /backup/postgres_backup.tar.gz /data
```

### Restore from Backup

```bash
# Import SQL backup
docker-compose exec -T db psql -U postgres easybacklog_development < backup.sql
```

### Reset to Clean State

```bash
# Remove all data and volumes
docker-compose down -v

# Restart fresh
docker-compose up
```

## Building Your Own Image

If you want to modify the application or build your own image:

See [DOCKER_BUILD_GUIDE.md](doc/DOCKER_BUILD_GUIDE.md) for:
- Building a custom image
- Modifying the application code
- Publishing to Docker Hub or other registries

## Optional: External Services

The application supports optional integrations that are **disabled by default**:

### SendGrid Email Notifications

1. Get API credentials from [SendGrid](https://sendgrid.com)
2. Add to `.env`:
   ```
   SENDGRID_USERNAME=your_username
   SENDGRID_PASSWORD=your_api_key
   ```
3. Restart: `docker-compose restart web`

### Ably Real-time Collaboration

The Ably gem is currently disabled. To enable real-time features:

1. Clone the repository and edit `Gemfile`: uncomment `gem 'ably'`
2. Get credentials from [Ably.io](https://ably.io)
3. Rebuild the image (see [DOCKER_BUILD_GUIDE.md](doc/DOCKER_BUILD_GUIDE.md))

## Documentation for Developers

If you want to develop on easyBacklog (not just run it), clone the repository and see:

- [LOCAL_DEVELOPMENT_GUIDE.md](doc/LOCAL_DEVELOPMENT_GUIDE.md) — Local development without Docker
- [DOCKER_GUIDE.md](doc/DOCKER_GUIDE.md) — Docker-specific development
- [EXTERNAL_SERVICES_GUIDE.md](doc/EXTERNAL_SERVICES_GUIDE.md) — External service integration
- [AUTHENTICATION_QUICK_REFERENCE.md](doc/AUTHENTICATION_QUICK_REFERENCE.md) — How authentication works
- [DOCKER_BUILD_GUIDE.md](doc/DOCKER_BUILD_GUIDE.md) — Building and publishing images

## Project History & Attribution

easyBacklog was created by [Matthew O'Riordan](https://mattheworiordan.com). The service shut down in September 2022, but is now open source under the MIT license.

See [README.md](README.md) for full project history and license details.

## Getting Help

- **Issues?** Check the [troubleshooting section](#troubleshooting) above
- **Questions?** Review the documentation in [doc/](doc/)
- **Contributing?** See the main repository for contribution guidelines
- **Bug reports?** Open an issue on GitHub

---

**Quick Links:**
- 🏠 [Project README](README.md)
- 📖 [Full Documentation](doc/)
- 🐳 [Docker Hub Image](https://hub.docker.com/r/mattanmr/easybacklog)
- 📝 [MIT License](LICENSE)
- 👤 [Original Creator](https://mattheworiordan.com)

---

Happy backlogs! 🎯

