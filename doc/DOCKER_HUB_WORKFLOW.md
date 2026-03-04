# Docker Hub Distribution Workflow - Complete Guide

This document provides a visual overview of how the Docker Hub distribution workflow works.

---

## The Complete Picture

```
┌─────────────────────────────────────────────────────────────────┐
│                    MAINTAINER (You)                              │
│                                                                  │
│  1. Make code changes                                           │
│  2. Build image: docker build -t yourusername/easybacklog .    │
│  3. Push to Hub: docker push yourusername/easybacklog:latest   │
│                                                                  │
│     OR use automation:                                          │
│     - Run: ./build-and-push.sh                                 │
│     - Or: GitHub Actions (auto-publish on commit)              │
│                                                                  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ Published to Docker Hub
                         │ (yourusername/easybacklog:latest)
                         │
                         ▼
         ┌───────────────────────────────────┐
         │       DOCKER HUB                  │
         │  hub.docker.com/r/yourusername/   │
         │       easybacklog                 │
         └───────────────┬───────────────────┘
                         │
                         │ Students pull images
                         │
         ┌───────────────▼───────────────────┐
         │                                    │
    ┌────▼────┐  ┌───────▼───────┐  ┌───────▼────────┐
    │Student 1│  │   Student 2   │  │   Student N    │
    │         │  │               │  │                │
    │ Pulls & │  │   Pulls &     │  │   Pulls &      │
    │  Runs   │  │    Runs       │  │    Runs        │
    └─────────┘  └───────────────┘  └────────────────┘
    
    Time: 2-3 min     Time: 2-3 min     Time: 2-3 min
    (just download)   (just download)   (just download)
```

---

## Detailed Workflow

### Phase 1: Maintainer Setup (One Time)

1. **Create Docker Hub account**
   - Go to https://hub.docker.com
   - Sign up (free for public repositories)
   - Note your username (e.g., `mattanmr`)

2. **Login to Docker Hub locally**
   ```bash
   docker login
   ```

3. **Build and tag the image**
   ```bash
   docker build -t mattanmr/easybacklog:latest .
   ```

4. **Push to Docker Hub**
   ```bash
   docker push mattanmr/easybacklog:latest
   ```

5. **Update docker-compose.prebuilt.yml**
   - Replace `yourusername` with `mattanmr` (your actual username)
   - Commit this change to the repository

6. **Share with students**
   - Give them the repository URL
   - Tell them to use `./quick-start-prebuilt.sh`

---

### Phase 2: Student Usage (Every Time)

1. **Clone repository**
   ```bash
   git clone https://github.com/mattanmr/easybacklog.git
   cd easybacklog
   ```

2. **Run quick start**
   ```bash
   ./quick-start-prebuilt.sh
   ```

3. **What happens automatically:**
   - Pulls `postgres:11` from Docker Hub (~100MB)
   - Pulls `redis:5-alpine` from Docker Hub (~30MB)
   - Pulls `mattanmr/easybacklog:latest` from Docker Hub (~800MB)
   - Starts all 4 services
   - Initializes database
   - Loads sample data
   - Shows access instructions

4. **Access the app**
   - Open http://localhost:3000
   - Login with demo@example.com / password123

**Total time:** 2-3 minutes (vs 10+ minutes with local build)

---

## What Gets Published to Docker Hub

### Single Image for Two Services

The `yourusername/easybacklog` image contains:
- Ruby 2.6.10 with all dependencies
- Rails 3.2 application code
- All Ruby gems installed
- Configuration and scripts

This **same image** is used for:
- `web` service (runs Rails server)
- `sidekiq` service (runs background jobs)

They just run different commands but use the same base image.

### Official Images (Already on Docker Hub)

Students also pull these official images:
- `postgres:11` - PostgreSQL database
- `redis:5-alpine` - Redis cache/queue

---

## Image Versioning Strategy

### Recommended Tags

| Tag | Purpose | Example | When to Use |
|-----|---------|---------|-------------|
| `latest` | Always the newest | `mattanmr/easybacklog:latest` | Default for students |
| `v1.0.0` | Specific version | `mattanmr/easybacklog:v1.0.0` | Stable releases |
| `v1.0` | Minor version | `mattanmr/easybacklog:v1.0` | Auto-updated patch versions |
| `main` | From main branch | `mattanmr/easybacklog:main` | Bleeding edge |

### Example Publishing Flow

```bash
# Release version 1.0.0
docker build -t mattanmr/easybacklog:v1.0.0 .
docker tag mattanmr/easybacklog:v1.0.0 mattanmr/easybacklog:v1.0
docker tag mattanmr/easybacklog:v1.0.0 mattanmr/easybacklog:latest

# Push all tags
docker push mattanmr/easybacklog:v1.0.0
docker push mattanmr/easybacklog:v1.0
docker push mattanmr/easybacklog:latest
```

Or use the script:
```bash
./build-and-push.sh v1.0.0
```

---

## GitHub Actions Automation (Optional)

### Setup (5 minutes)

1. **Get Docker Hub token**
   - Docker Hub > Account Settings > Security
   - Create "New Access Token"
   - Copy the token

2. **Add to GitHub Secrets**
   - GitHub repo > Settings > Secrets > Actions
   - Add `DOCKER_HUB_USERNAME` (your username)
   - Add `DOCKER_HUB_TOKEN` (the token)

3. **Activate workflow**
   ```bash
   cp .github/workflows/docker-publish.yml.template .github/workflows/docker-publish.yml
   # Edit file: replace 'yourusername' with your Docker Hub username
   git add .github/workflows/docker-publish.yml
   git commit -m "Enable automatic Docker Hub publishing"
   git push
   ```

### What Happens Automatically

**On every push to main:**
- GitHub Actions builds the image
- Pushes to Docker Hub as `latest`
- Takes ~5-10 minutes

**On version tags (e.g., v1.0.0):**
- Builds and pushes as `v1.0.0`, `1.0`, and `latest`
- Creates versioned releases

**Students benefit:**
- Always get the latest code
- Don't wait for builds
- Consistent experience

---

## Cost Analysis

### Docker Hub Free Tier

- ✅ Unlimited public repositories
- ✅ Unlimited pulls
- ✅ One private repository
- ✅ More than enough for educational use

**Cost for maintainer:** $0  
**Cost for students:** $0  

### GitHub Actions Free Tier

- ✅ 2,000 minutes/month for public repositories
- ✅ Each build takes ~10 minutes
- ✅ = 200 builds/month for free
- ✅ More than enough for educational repositories

**Cost for maintainer:** $0  

---

## Bandwidth Comparison

### Building Locally (Current)
**Student downloads:**
- Base images: ~200MB (postgres, redis, ruby base)
- Source code: ~10MB (from git)
- Gem dependencies during build: ~100MB
- **Total: ~310MB + build time**

### Pulling from Docker Hub (New)
**Student downloads:**
- `postgres:11`: ~100MB
- `redis:5-alpine`: ~30MB
- `yourusername/easybacklog:latest`: ~800MB
- **Total: ~930MB, no build time**

**Trade-off:** Larger download, but no build time = faster overall setup

---

## Real-World Example

### Your Setup (mattanmr)

1. **Build and publish**
   ```bash
   docker build -t mattanmr/easybacklog:latest .
   docker push mattanmr/easybacklog:latest
   ```

2. **Update docker-compose.prebuilt.yml**
   ```yaml
   web:
     image: mattanmr/easybacklog:latest
   sidekiq:
     image: mattanmr/easybacklog:latest
   ```

3. **Students use**
   ```bash
   git clone https://github.com/mattanmr/easybacklog.git
   cd easybacklog
   ./quick-start-prebuilt.sh
   ```

4. **Result**
   - Images pulled from `hub.docker.com/r/mattanmr/easybacklog`
   - 20+ students can pull simultaneously
   - Each student ready in 2-3 minutes
   - No build errors or inconsistencies

---

## FAQ

**Q: Do I need to rebuild for every code change?**  
A: Yes, but only you (maintainer) rebuild. Students always pull the latest.

**Q: Can students modify the code?**  
A: With docker-compose.prebuilt.yml, no (image is pre-built). For code changes, students should use docker-compose.yml (local build version).

**Q: What if Docker Hub is down?**  
A: Students can fall back to local builds with `./quick-start-compose.sh`

**Q: Can I use a private repository?**  
A: Yes, but students would need Docker Hub accounts and access. Public is better for education.

**Q: How do I update the image?**  
A: Just rebuild and push again. Students run `docker compose pull` to get the latest.

---

## Maintenance Schedule

**Recommended workflow:**

1. **Daily/Weekly:** Use GitHub Actions for automatic publishing
2. **Major changes:** Manually build and test before pushing
3. **Releases:** Create version tags (v1.0.0, v1.1.0, etc.)
4. **Cleanup:** Remove old tags from Docker Hub periodically

---

## Summary

**Traditional approach:**
- Student builds locally
- 10+ minute setup
- Requires build tools
- May fail on some machines

**Docker Hub approach:**
- Maintainer builds once
- Students pull pre-built image
- 2-3 minute setup
- Consistent for all students
- No build tools needed

**Winner:** Docker Hub approach for distributing to students! 🏆

---

See full instructions in [DOCKER_HUB_PUBLISHING.md](DOCKER_HUB_PUBLISHING.md)
