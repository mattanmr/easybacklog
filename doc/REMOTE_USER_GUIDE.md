# Remote User / Student Quick Setup Guide

This is the simplest guide to get easyBacklog running on your machine. No prior knowledge required!

---

## What You Need

**Only one thing:** Docker Desktop

Download and install from: https://www.docker.com/products/docker-desktop

- **Mac users**: Docker Desktop for Mac
- **Windows users**: Docker Desktop for Windows  
- **Linux users**: Docker Desktop for Linux

After installing, make sure Docker Desktop is running (you should see the whale icon in your system tray).

---

## Three Ways to Run easyBacklog

Choose the approach that works best for you:

### Method 1: Pre-Built Images from Docker Hub (Fastest! ⚡)

**What you get:** Pull pre-built images (no 5-minute build wait!)

**When available:** If your instructor has published images to Docker Hub

#### Step 1: Download the project
```bash
git clone https://github.com/mattanmr/easybacklog.git
cd easybacklog
```

*Don't have git? Download as ZIP from GitHub and extract it.*

#### Step 2: Run the quick start script
```bash
./quick-start-prebuilt.sh
```

**That's it!** Wait 2-3 minutes to download and start, then open http://localhost:3000

**Time saved:** Skip the 5-minute build process!

---

### Method 2: Standalone Image (Build Locally - Simple)

**What you get:** Everything in one container, build it yourself.

#### Step 1: Download the project
```bash
git clone https://github.com/mattanmr/easybacklog.git
cd easybacklog
```

*Don't have git? Download as ZIP from GitHub and extract it.*

#### Step 2: Run the quick start script
```bash
./quick-start.sh
```

**That's it!** Wait 5-10 minutes for the first-time setup, then open http://localhost:3000

#### Login Credentials
- **Email:** demo@example.com
- **Password:** password123

---

### Method 3: Docker Compose (Build Locally - Recommended for Learning)

**What you get:** Separate containers for database, cache, web server, and background jobs. Better for learning.

#### Step 1: Download the project
```bash
git clone https://github.com/mattanmr/easybacklog.git
cd easybacklog
```

#### Step 2: Run the quick start script
```bash
./quick-start-compose.sh
```

**That's it!** Wait 5-10 minutes for the first-time setup, then open http://localhost:3000

#### Or use the Makefile (if you prefer)
```bash
make setup-with-sample
```

#### Login Credentials
- **Email:** demo@example.com
- **Password:** password123

---

## Verify It's Working

Open your browser to: **http://localhost:3000**

You should see the easyBacklog homepage. Click "Sign In" and use the demo credentials above.

---

## What to Do Next

Once you're logged in:

1. **Explore the backlog** - You'll see a sample "E-commerce Project" with themes and stories
2. **Create a sprint** - Try organizing stories into sprints
3. **Experiment** - Add new stories, modify themes, explore the interface
4. **Look at the code** - Check out the files in the `app/` directory

---

## Useful Commands

### View What's Running
```bash
docker ps
```

### View Logs (if something isn't working)

**For standalone image:**
```bash
docker logs -f easybacklog
```

**For Docker Compose:**
```bash
docker compose logs -f web
```

### Stop the Application

**For standalone image:**
```bash
docker stop easybacklog
```

**For Docker Compose:**
```bash
docker compose down
```

### Start Again

**For standalone image:**
```bash
docker start easybacklog
```

**For Docker Compose:**
```bash
docker compose up -d
```

---

## Troubleshooting

### "Port already in use" error

Something else is using port 3000 on your machine.

**Solution:** Stop the other application, or change the port:

**Standalone:**
```bash
docker run -p 3001:3000 easybacklog:latest
```
Then access at http://localhost:3001

**Docker Compose:** Edit `docker-compose.yml` and change `"3000:3000"` to `"3001:3000"`

### "Docker is not running" error

Start Docker Desktop. You should see the whale icon in your system tray (Mac/Windows) or run `sudo systemctl start docker` (Linux).

### Application won't load / shows errors

1. Wait a bit longer (first startup takes ~30-60 seconds)
2. Check logs:
   - Standalone: `docker logs easybacklog`
   - Compose: `docker compose logs web`
3. Try restarting:
   - Standalone: `docker restart easybacklog`
   - Compose: `docker compose restart web`

### "Database doesn't exist" error

**For Docker Compose only:**
**For pre-built images (docker-compose.prebuilt.yml):**
```bash
docker compose -f docker-compose.prebuilt.yml exec web bundle exec rake db:schema:load
docker compose -f docker-compose.prebuilt.yml exec web bundle exec rake db:seed
```

**For local build (docker-compose.yml):**
```bash
docker compose exec web bundle exec rake db:schema:load
docker compose exec web bundle exec rake db:seed
```

### Need to start completely fresh?

**Standalone:**
```bash
docker rm -f easybacklog
docker rmi easybacklog:latest
./quick-start.sh
```

**Docker Compose (with pre-built images):**
```bash
docker compose -f docker-compose.prebuilt.yml down -v
./quick-start-prebuilt.sh
```

**Docker Compose (local build):**
```bash
docker compose down -v
make setup
```

---

## Getting Help

If you're still stuck:

1. **Check the detailed guides:**
   - [GETTING_STARTED.md](GETTING_STARTED.md) - Comprehensive guide
   - [DOCKER_GUIDE.md](DOCKER_GUIDE.md) - All Docker commands
   - [STANDALONE_DOCKER_IMAGE.md](STANDALONE_DOCKER_IMAGE.md) - Standalone image details
   - [DOCKER_HUB_PUBLISHING.md](DOCKER_HUB_PUBLISHING.md) - Pre-built images guide

2. **Check the logs** for error messages and search for them online

3. **Ask your instructor** or **create a GitHub issue** with:
   - What command you ran
   - What error you got
   - Your operating system
   - Output of `docker --version`

---

## Summary

**Fastest way to get started:**

**If images are on Docker Hub (fastest):**
1. Install Docker Desktop
2. Clone the repository
3. Run `./quick-start-prebuilt.sh`
4. Open http://localhost:3000
5. Login with demo@example.com / password123

**If building locally:**
1. Install Docker Desktop
2. Clone the repository
3. Run `./quick-start-compose.sh` (recommended) or `./quick-start.sh` (simpler)
4. Open http://localhost:3000
5. Login with demo@example.com / password123

**That's all you need!** 🎉

---

For more advanced usage and learning paths, see [GETTING_STARTED.md](GETTING_STARTED.md).
