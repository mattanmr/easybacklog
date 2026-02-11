# Docker Operations Guide

This guide covers all Docker operations for the EasyBacklog application.

---

## 1. Complete Teardown and Cleanup

Use this when you want to completely remove everything and start from scratch.

### Full Cleanup (All Data Lost)
```powershell
# Stop and remove all containers, networks, and volumes
docker-compose down -v

# Remove the application images
docker image rm easybacklog-web easybacklog-sidekiq

# Optional: Remove base images (PostgreSQL, Redis) to free space
docker image rm postgres:11 redis:5
```

### Verify Cleanup
```powershell
# Check that containers are gone
docker-compose ps

# Check remaining images
docker images | Select-String "easybacklog|postgres|redis"
```

---

## 2. Initial Setup and Load Up

Use this for the **first time** setup or after a complete cleanup.

### Step 1: Start Database and Redis
```powershell
docker-compose up -d db redis
```
Wait a few seconds for the database to initialize.

### Step 2: Build and Start Application Services
```powershell
docker-compose up -d --build web sidekiq
```
This builds the images and starts both the web server and background worker.

### Step 3: Load Database Schema
```powershell
docker-compose run --rm web bundle exec rake db:schema:load
```
⚠️ **Important:** Use `db:schema:load` NOT `db:migrate` - the old migrations have Devise compatibility issues.

### Step 4: Seed Database with Initial Data
```powershell
docker-compose run --rm web bundle exec rake db:seed
```
This populates:
- Locales (en_US, en_GB, de_DE, fr_FR, es_ES, it_IT)
- Sprint story statuses
- Scoring rules

### Step 5: Verify Services
```powershell
# Check all services are running
docker-compose ps

# Test the application
Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing | Select-Object StatusCode
```
You should see `StatusCode: 200`.

### Step 6: Access the Application
Open your browser to: **http://localhost:3000**

---

## 3. Shutting Down

### Regular Shutdown (Preserves Data)
```powershell
# Stop all containers but keep volumes (database data preserved)
docker-compose down
```

### Shutdown for Updates/Changes

**For Code Changes:**
```powershell
# Just restart the web service (no need to stop everything)
docker-compose restart web
```

**For Gemfile Changes:**
```powershell
# Stop services
docker-compose down

# Rebuild and restart
docker-compose up -d --build web sidekiq
```

**For Database Schema Changes:**
```powershell
# Stop services
docker-compose down

# Start services
docker-compose up -d

# Run migrations or load schema
docker-compose run --rm web bundle exec rake db:migrate
# OR for major schema changes:
docker-compose run --rm web bundle exec rake db:schema:load db:seed
```

---

## 4. Regular Load Up

Use this when containers are stopped but data/images exist.

### Quick Start (Most Common)
```powershell
docker-compose up -d
```
This starts all services (db, redis, web, sidekiq) in the background.

### Start with Log Output (Debugging)
```powershell
# Start and watch logs in foreground
docker-compose up

# Or start in background and follow logs
docker-compose up -d
docker-compose logs -f
```

### Start Specific Services Only
```powershell
# Start only database and web server
docker-compose up -d db web
```

### Verify Services
```powershell
# Check running containers
docker-compose ps

# Check specific service logs
docker-compose logs web
docker-compose logs sidekiq

# Follow logs in real-time
docker-compose logs -f web
```

---

## 5. Other Useful Operations

### View Logs
```powershell
# All services
docker-compose logs

# Specific service
docker-compose logs web

# Last 50 lines
docker-compose logs --tail=50 web

# Follow logs in real-time
docker-compose logs -f web

# Search logs for errors
docker-compose logs web | Select-String "ERROR|Exception"
```

### Restart Services
```powershell
# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart web
```

### Run Commands in Containers
```powershell
# Run Rails console
docker-compose run --rm web bundle exec rails console

# Run rake tasks
docker-compose run --rm web bundle exec rake db:seed

# Run Cucumber tests
docker-compose run --rm web bundle exec cucumber

# Run RSpec tests
docker-compose run --rm web bundle exec rspec

# Access bash shell in web container
docker-compose run --rm web bash
```

### Database Operations
```powershell
# Access PostgreSQL console
docker-compose exec db psql -U postgres -d easybacklog_development

# Backup database
docker-compose exec db pg_dump -U postgres easybacklog_development > backup.sql

# Restore database
cat backup.sql | docker-compose exec -T db psql -U postgres easybacklog_development

# Reset database (DESTRUCTIVE)
docker-compose run --rm web bundle exec rake db:drop db:schema:load db:seed
```

### Bundle Operations
```powershell
# Install new gems after Gemfile changes
docker-compose run --rm web bundle install

# Update all gems
docker-compose run --rm web bundle update

# Check for outdated gems
docker-compose run --rm web bundle outdated
```

### Check Service Status
```powershell
# List running containers
docker-compose ps

# View container resource usage
docker stats

# Check specific service health
docker-compose exec web ps aux

# Check database connection
docker-compose exec web bundle exec rails runner "puts ActiveRecord::Base.connection.active? ? 'Connected' : 'Not Connected'"
```

### Clean Up Without Full Teardown
```powershell
# Remove stopped containers
docker-compose rm

# Remove unused images (frees disk space)
docker image prune -a

# Remove unused volumes (CAUTION: may delete data)
docker volume prune

# Remove everything unused (CAUTION)
docker system prune -a --volumes
```

---

## Troubleshooting

### Container Won't Start
```powershell
# Check logs for errors
docker-compose logs web

# Check if port is already in use
netstat -ano | findstr :3000

# Rebuild the container
docker-compose down
docker-compose up -d --build web
```

### Database Connection Errors
```powershell
# Check if database is running
docker-compose ps db

# Restart database
docker-compose restart db

# Check database logs
docker-compose logs db
```

### Gem Missing Errors
```powershell
# Reinstall gems
docker-compose run --rm web bundle install

# Rebuild container with gems
docker-compose down
docker-compose up -d --build web sidekiq
```

### "Locale Not Valid" Errors
The application includes fixes for locale normalization (converting `en_US` to `en-US` format). If you still see locale errors, check:
- Database has seeded locales: `docker-compose run --rm web bundle exec rails runner "puts Locale.all.map(&:code)"`
- Latest code changes are committed and container rebuilt

### Reset to Known Good State
```powershell
# Complete reset (DESTRUCTIVE - all data lost)
docker-compose down -v
docker image rm easybacklog-web easybacklog-sidekiq
docker-compose up -d --build
docker-compose run --rm web bundle exec rake db:schema:load db:seed
```

---

## Service URLs

- **Web Application:** http://localhost:3000
- **PostgreSQL:** localhost:5432 (user: `postgres`, password: `password`, db: `easybacklog_development`)
- **Redis:** localhost:6379

---

## Quick Reference

| Task | Command |
|------|---------|
| Start everything | `docker-compose up -d` |
| Stop everything | `docker-compose down` |
| View logs | `docker-compose logs -f` |
| Restart web | `docker-compose restart web` |
| Rails console | `docker-compose run --rm web bundle exec rails console` |
| Run tests | `docker-compose run --rm web bundle exec cucumber` |
| Database console | `docker-compose exec db psql -U postgres -d easybacklog_development` |
| Install gems | `docker-compose run --rm web bundle install` |
| Reset database | `docker-compose run --rm web bundle exec rake db:drop db:schema:load db:seed` |
| Clean everything | `docker-compose down -v && docker image rm easybacklog-web easybacklog-sidekiq` |

---

## Development Workflow

### Typical Daily Workflow
```powershell
# Morning: Start services
docker-compose up -d

# Make code changes in your editor...

# If you changed Ruby code, restart web server
docker-compose restart web

# Run tests
docker-compose run --rm web bundle exec cucumber

# Check logs if something breaks
docker-compose logs -f web

# Evening: Stop services
docker-compose down
```

### After Pulling Code Changes
```powershell
# If Gemfile changed
docker-compose run --rm web bundle install
docker-compose restart web

# If migrations added
docker-compose run --rm web bundle exec rake db:migrate

# If seed data changed
docker-compose run --rm web bundle exec rake db:seed
```

---

## Notes

- **Data Persistence:** Database data is stored in Docker volumes and persists across container restarts unless you use `docker-compose down -v`
- **Bundle Cache:** Gems are cached in a volume for faster rebuilds
- **Development Mode:** The application runs in development mode by default (see `docker-compose.yml`)
- **External Services:** Email, analytics, and other external services are disabled by default (controlled by environment variables)
