# Student Instructions for Pre-Built Docker Images

**Instructor has published images to Docker Hub - you don't need to build anything!**

---

## Setup (5 Minutes)

### Prerequisites
- Docker Desktop installed and running

### Steps

1. **Download the project files**
   ```bash
   git clone https://github.com/mattanmr/easybacklog.git
   cd easybacklog
   ```

2. **Run the quick start script**
   ```bash
   ./quick-start-prebuilt.sh
   ```

3. **Open your browser**
   - Go to: http://localhost:3000
   - Login with: demo@example.com / password123

**Done!** 🎉

---

## What This Does

- ✅ Pulls pre-built images from Docker Hub (no building!)
- ✅ Starts 4 services: database, cache, web server, background jobs
- ✅ Initializes database with sample data
- ✅ Ready in 2-3 minutes (vs 10+ minutes with local build)

---

## Common Commands

```bash
# View logs
docker compose -f docker-compose.prebuilt.yml logs -f web

# Stop everything
docker compose -f docker-compose.prebuilt.yml down

# Start again
docker compose -f docker-compose.prebuilt.yml up -d

# Open Rails console
docker compose -f docker-compose.prebuilt.yml exec web bundle exec rails console
```

---

## Troubleshooting

**"Image not found" error?**
- The instructor hasn't published images yet
- Use `./quick-start-compose.sh` instead (builds locally)

**Port 3000 already in use?**
- Stop other applications using that port
- Or edit docker-compose.prebuilt.yml to use a different port

---

**Need more help?** See [REMOTE_USER_GUIDE.md](REMOTE_USER_GUIDE.md) for detailed instructions.
