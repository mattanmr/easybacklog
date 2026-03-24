# Docker Setup Guide: Which File to Use?

## Overview

There are two Docker Compose files in this repository, each for a different use case:

| File | Use Case | Target Users |
|------|----------|--------------|
| [`docker-compose.yml`](docker-compose.yml) | **Local development & building** | Contributors & maintainers |
| [`docker-compose.example.yml`](docker-compose.example.yml) | **Running pre-built image** | End users |

## For End Users: Use `docker-compose.example.yml`

If you just want to **run easyBacklog**, use the example file:

```bash
# Setup (one time)
mkdir easybacklog && cd easybacklog
curl -o docker-compose.yml https://raw.githubusercontent.com/mattanmr/easybacklog/main/docker-compose.example.yml
curl -o .env https://raw.githubusercontent.com/mattanmr/easybacklog/main/.env.example

# Run
docker-compose up
```

This file:
- ✅ Downloads a pre-built image from Docker Hub (no building required)
- ✅ Works immediately with `docker-compose up`
- ✅ Minimal setup needed (just .env configuration)
- ✅ Fastest to get running

**See:** [QUICKSTART.md](QUICKSTART.md) for complete user setup guide.

## For Developers: Use `docker-compose.yml`

If you want to **modify the code** or **build your own image**:

```bash
# Clone repository
git clone https://github.com/mattanmr/easybacklog.git
cd easybacklog

# Build and run locally
docker-compose up
```

This file:
- ✅ Builds the Docker image locally from the Dockerfile
- ✅ Includes the full source code in your container
- ✅ Perfect for development and testing changes
- ✅ Allows rebuilding and customization

**See:** [DOCKER_BUILD_GUIDE.md](doc/DOCKER_BUILD_GUIDE.md) for building and publishing instructions.

## Key Differences

### Image Source

**`docker-compose.yml`** (developer):
```yaml
web:
  build: .                    # Builds from local Dockerfile
  volumes:
    - .:/app                  # Code changes live-reloaded
```

**`docker-compose.example.yml`** (user):
```yaml
web:
  image: mattanmr/easybacklog:latest   # Pre-built from Docker Hub
  # No build or volume mounts
```

### Database Initialization

**Both files** auto-initialize the database on first run. No manual setup needed.

### Configuration

**Both files** use a `.env` file for configuration. Copy from `.env.example`:

```bash
cp .env.example .env
```

## Switching Between Workflows

### As a User: Want to Contribute Code?

```bash
# Switch from using pre-built image to local development
git clone https://github.com/mattanmr/easybacklog.git
cd easybacklog
docker-compose up                    # Uses docker-compose.yml (this repo)
```

### As a Developer: Want to Just Run It?

```bash
cd /path/to/easybacklog
# Temporarily use the example file without cloning
curl -o docker-compose.yml docker-compose.example.yml
docker-compose up
```

(This works, but then you'll need to manage code changes manually.)

## Building and Publishing

To publish your own image to Docker Hub:

```bash
# Build
docker build -t yourusername/easybacklog:latest .

# Publish
docker login
docker push yourusername/easybacklog:latest

# Users can then run it
export DOCKER_IMAGE=yourusername/easybacklog:latest
docker-compose -f docker-compose.example.yml up
```

**See:** [DOCKER_BUILD_GUIDE.md](doc/DOCKER_BUILD_GUIDE.md) for complete instructions.

## What If Docker Hub Image Isn't Available Yet?

Until an official Docker Hub image is published, users can:

1. **Clone the repo** and use `docker-compose.yml` (builds locally)
2. **Build and publish** their own image following [DOCKER_BUILD_GUIDE.md](doc/DOCKER_BUILD_GUIDE.md)
3. **Wait** for the official Docker Hub publish (recommended for most users)

## Troubleshooting

### "Image not found" Error

```
error: "image not found: mattanmr/easybacklog:latest"
```

**Solution:** Either:
- A) Build from source: Clone repo and use `docker-compose.yml`
- B) Use a published image: Update `DOCKER_IMAGE` in `.env`

Example:
```bash
export DOCKER_IMAGE=myname/easybacklog:latest
docker-compose -f docker-compose.example.yml up
```

### Want to Use a Different Image?

Edit `docker-compose.example.yml` or set the environment variable:

```bash
# Use a specific version
export DOCKER_IMAGE=mattanmr/easybacklog:v1.0.0
docker-compose up

# Or customize docker-compose.yml:
sed -i '' 's/easybacklog\/easybacklog:latest/myname\/myimage:tag/g' docker-compose.yml
docker-compose up
```

## Summary

```
Users:        docker-compose.example.yml → Docker Hub image → "docker-compose up" → Done ✅
Developers:   docker-compose.yml → build locally → test → publish to Hub
```

---

**Questions?** See [QUICKSTART.md](QUICKSTART.md) for user setup or [DOCKER_BUILD_GUIDE.md](doc/DOCKER_BUILD_GUIDE.md) for developer builds.
