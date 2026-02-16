# Building and Running easyBacklog as a Docker Image

This guide explains how to build and run easyBacklog as a standalone Docker image.

---

## Quickest Start (1 Command)

Use the automated quick-start script:

```bash
./quick-start.sh
```

This script automatically:
- Checks Docker is installed and running
- Builds the image
- Runs the container
- Provides instructions for accessing the app

---

## Quick Start (2 Commands)

Or build and run manually:

```bash
# 1. Build the image (takes ~5 minutes first time)
docker build -f Dockerfile.standalone -t easybacklog:latest .

# 2. Run the container
docker run -p 3000:3000 easybacklog:latest
```

Then open your browser to **http://localhost:3000**

**Demo credentials:**
- Email: `demo@example.com`
- Password: `password123`

---

## What This Does

The standalone Docker image:
- ✅ Includes PostgreSQL database in the same container
- ✅ Automatically initializes the database on first run
- ✅ Loads sample data (demo account with backlog and stories)
- ✅ Starts the Rails web server on port 3000
- ✅ Self-contained - no external dependencies needed

---

## Detailed Instructions

### Step 1: Build the Image

```bash
docker build -f Dockerfile.standalone -t easybacklog:latest .
```

**What this does:**
- Installs Ruby 2.6.10 and all dependencies
- Installs PostgreSQL 11 server
- Installs all Ruby gems
- Copies the application code
- Creates a startup script

**Build time:** ~5 minutes on first build, ~30 seconds on subsequent builds (with layer caching)

### Step 2: Run the Container

#### Basic Run (with sample data)
```bash
docker run -p 3000:3000 easybacklog:latest
```

#### Run without sample data
```bash
docker run -e LOAD_SAMPLE_DATA=false -p 3000:3000 easybacklog:latest
```

#### Run in detached mode (background)
```bash
docker run -d -p 3000:3000 --name easybacklog easybacklog:latest
```

#### Run with persistent data (survives container restart)
```bash
docker run -p 3000:3000 -v easybacklog_data:/var/lib/postgresql easybacklog:latest
```

### Step 3: Access the Application

Open your browser to: **http://localhost:3000**

---

## Container Lifecycle

### View logs
```bash
# If running in detached mode
docker logs -f easybacklog
```

### Stop the container
```bash
docker stop easybacklog
```

### Start the container again
```bash
docker start easybacklog
```

### Remove the container
```bash
docker rm -f easybacklog
```

### Remove the image
```bash
docker rmi easybacklog:latest
```

---

## Advanced Usage

### Custom Port Mapping
```bash
# Run on port 8080 instead of 3000
docker run -p 8080:3000 easybacklog:latest
```

### Interactive Shell Access
```bash
# Start a shell inside the running container
docker exec -it easybacklog bash

# Inside the container, you can:
cd /app
bundle exec rails console  # Open Rails console
psql -U postgres -d easybacklog_development  # Access database
```

### Rebuild After Code Changes
```bash
# Rebuild the image
docker build -f Dockerfile.standalone -t easybacklog:latest .

# Stop and remove old container
docker rm -f easybacklog

# Run new container
docker run -p 3000:3000 --name easybacklog easybacklog:latest
```

---

## Troubleshooting

### Port Already in Use
If you see "port is already allocated":
```bash
# Use a different port
docker run -p 3001:3000 easybacklog:latest
```

### Container Exits Immediately
Check the logs:
```bash
docker logs easybacklog
```

### Database Issues
The database is created fresh each time you start a new container. To persist data:
```bash
docker run -p 3000:3000 -v easybacklog_data:/var/lib/postgresql/11/main easybacklog:latest
```

### Out of Disk Space
Docker images can be large. Clean up:
```bash
# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune
```

---

## Comparison: Standalone vs Docker Compose

| Feature | Standalone Image | Docker Compose |
|---------|------------------|----------------|
| **Commands** | 2 (build + run) | 1 (compose up) |
| **Services** | All-in-one container | 4 separate containers |
| **Database** | PostgreSQL (embedded) | PostgreSQL (separate) |
| **Redis** | Not included | Separate container |
| **Sidekiq** | Not running | Separate container |
| **Live Reload** | No | Yes (volume mount) |
| **Best For** | Quick demos, distribution | Development, learning |
| **Image Size** | ~1.5 GB | ~800 MB (web only) |
| **Startup Time** | ~30 seconds | ~10 seconds |
| **Data Persistence** | Requires volume | Automatic |

**Recommendation:**
- **Use Standalone** for: Quick demos, sharing with students, simple deployments
- **Use Docker Compose** for: Active development, learning about microservices, full feature set

---

## Student Instructions

### For Instructors: Share the Image

**Option 1: Share Dockerfile**
```bash
# Students clone and build
git clone https://github.com/mattanmr/easybacklog.git
cd easybacklog
docker build -f Dockerfile.standalone -t easybacklog:latest .
docker run -p 3000:3000 easybacklog:latest
```

**Option 2: Export/Import Image**
```bash
# Instructor: Build and export
docker build -f Dockerfile.standalone -t easybacklog:latest .
docker save easybacklog:latest | gzip > easybacklog-image.tar.gz

# Students: Import and run
docker load < easybacklog-image.tar.gz
docker run -p 3000:3000 easybacklog:latest
```

**Option 3: Push to Registry (if available)**
```bash
# Instructor: Tag and push
docker tag easybacklog:latest your-registry/easybacklog:latest
docker push your-registry/easybacklog:latest

# Students: Pull and run
docker pull your-registry/easybacklog:latest
docker run -p 3000:3000 your-registry/easybacklog:latest
```

### For Students: Getting Started

1. **Install Docker Desktop**
   - Mac: https://docs.docker.com/desktop/install/mac-install/
   - Windows: https://docs.docker.com/desktop/install/windows-install/
   - Linux: https://docs.docker.com/desktop/install/linux-install/

2. **Get the Code**
   ```bash
   git clone https://github.com/mattanmr/easybacklog.git
   cd easybacklog
   ```

3. **Build the Image**
   ```bash
   docker build -f Dockerfile.standalone -t easybacklog:latest .
   ```
   *(This takes about 5 minutes - get a coffee! ☕)*

4. **Run the Container**
   ```bash
   docker run -p 3000:3000 easybacklog:latest
   ```
   *(Wait 30 seconds for startup)*

5. **Explore the App**
   - Open http://localhost:3000
   - Login with demo@example.com / password123
   - Explore backlogs, themes, and stories!

6. **When Done**
   - Press `Ctrl+C` to stop
   - Or `docker stop easybacklog` if running detached

---

## Next Steps

After getting the standalone image running:

1. **Try the Docker Compose version** for a more realistic multi-service setup:
   ```bash
   docker compose up -d
   ```

2. **Read the documentation**:
   - [GETTING_STARTED.md](GETTING_STARTED.md) - Learning paths and exercises
   - [DOCKER_GUIDE.md](DOCKER_GUIDE.md) - Comprehensive Docker operations

3. **Experiment**:
   - Modify the code
   - Rebuild the image
   - See your changes in action

4. **Learn more**:
   - Explore Rails console: `docker exec -it easybacklog bundle exec rails console`
   - Check the database: `docker exec -it easybacklog psql -U postgres -d easybacklog_development`
   - View logs: `docker logs -f easybacklog`

---

## Technical Details

### What's Inside the Image?

- **Base**: Ruby 2.6.10 on Debian Bullseye
- **Database**: PostgreSQL 13 (embedded, version from Debian Bullseye)
- **Web Server**: Thin (Rails default development server)
- **Application**: easyBacklog Rails 3.2 app with all dependencies
- **Sample Data**: Demo user, account, backlog, themes, and stories

### Startup Process

When you run the container:
1. PostgreSQL is initialized (if first run)
2. PostgreSQL server starts
3. Database is created (if doesn't exist)
4. Schema is loaded
5. Seed data is loaded
6. Sample data is loaded (if enabled)
7. Rails server starts on port 3000

### Performance

- **Image Size**: ~1.5 GB (includes PostgreSQL, Ruby, and all dependencies)
- **Build Time**: ~5 minutes (first build), ~30 seconds (cached)
- **Startup Time**: ~30 seconds (database initialization + app startup)
- **Memory Usage**: ~500 MB (PostgreSQL + Rails)
- **CPU Usage**: Low (idle), Medium (during requests)

---

## Frequently Asked Questions

**Q: Can I use this in production?**  
A: Not recommended. This is designed for learning and development. For production:
- Use separate database server
- Use proper web server (not Thin)
- Enable SSL/TLS
- Set proper environment variables
- Use Redis for caching and background jobs

**Q: Why is the image so large?**  
A: It includes PostgreSQL server, Ruby, system libraries, and all gem dependencies. This is the trade-off for having everything in one container.

**Q: Can I modify the code and rebuild?**  
A: Yes! Just:
1. Make your changes
2. Rebuild: `docker build -f Dockerfile.standalone -t easybacklog:latest .`
3. Run: `docker run -p 3000:3000 easybacklog:latest`

**Q: How do I persist data between runs?**  
A: Use a volume:
```bash
docker run -p 3000:3000 -v easybacklog_data:/var/lib/postgresql easybacklog:latest
```

**Q: Can I run multiple instances?**  
A: Yes, but use different ports:
```bash
docker run -p 3001:3000 easybacklog:latest  # Instance 1
docker run -p 3002:3000 easybacklog:latest  # Instance 2
```

**Q: What if I want background jobs (Sidekiq)?**  
A: Use the Docker Compose setup instead - it includes Sidekiq and Redis.

---

**Questions or Issues?** Check the main [README.md](../README.md) or [GETTING_STARTED.md](GETTING_STARTED.md) for more help.
