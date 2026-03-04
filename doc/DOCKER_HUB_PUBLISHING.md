# Publishing Docker Images to Docker Hub for Student Distribution

This guide explains how to build and publish easyBacklog Docker images to Docker Hub, allowing students to pull pre-built images instead of building locally.

---

## Overview

**Current Workflow:** Students build the image locally (slow, requires build tools)  
**New Workflow:** Students pull pre-built image from Docker Hub (fast, no build tools needed)

**Benefits:**
- ✅ Faster setup for students (no 5-minute build wait)
- ✅ No build dependencies needed on student machines
- ✅ Consistent image across all students
- ✅ Lower bandwidth usage (pull vs build)
- ✅ Works even on low-spec machines

---

## Prerequisites

1. **Docker Hub Account**
   - Sign up at: https://hub.docker.com
   - Create a free account (allows unlimited public repositories)
   - Note your Docker Hub username (e.g., `mattanmr`)

2. **Docker Installed Locally**
   - You need Docker to build and push images
   - Make sure Docker Desktop is running

---

## Step-by-Step Guide for Maintainers

### Step 1: Login to Docker Hub

```bash
docker login
```

Enter your Docker Hub username and password when prompted.

### Step 2: Build the Image with a Tag

Build the image and tag it for Docker Hub:

```bash
# Replace 'yourusername' with your actual Docker Hub username
docker build -t yourusername/easybacklog:latest .

# You can also add version tags
docker build -t yourusername/easybacklog:v1.0.0 .
```

**Example with mattanmr:**
```bash
docker build -t mattanmr/easybacklog:latest .
docker build -t mattanmr/easybacklog:v1.0.0 .
```

**Build time:** ~3-5 minutes

### Step 3: Test the Image Locally

Before pushing, test the image works:

```bash
docker run -p 3000:3000 yourusername/easybacklog:latest
```

Verify it starts correctly and the application is accessible.

### Step 4: Push to Docker Hub

```bash
# Push the latest tag
docker push yourusername/easybacklog:latest

# Push version tag (if created)
docker push yourusername/easybacklog:v1.0.0
```

**Example:**
```bash
docker push mattanmr/easybacklog:latest
docker push mattanmr/easybacklog:v1.0.0
```

**Upload time:** ~5-10 minutes (depends on internet speed and image size ~800MB)

### Step 5: Update docker-compose.prebuilt.yml

Edit `docker-compose.prebuilt.yml` and replace `yourusername` with your Docker Hub username:

```yaml
web:
  image: mattanmr/easybacklog:latest  # Your Docker Hub image

sidekiq:
  image: mattanmr/easybacklog:latest  # Your Docker Hub image
```

### Step 6: Commit the Change

```bash
git add docker-compose.prebuilt.yml
git commit -m "Update Docker Hub username in prebuilt compose file"
git push
```

### Step 7: Verify Students Can Pull

Test as a student would:

```bash
# Remove local images to simulate fresh pull
docker rmi mattanmr/easybacklog:latest

# Pull and run
docker compose -f docker-compose.prebuilt.yml up -d
```

---

## Updating the Image (When Code Changes)

When you make changes to the code:

### Step 1: Rebuild with New Version Tag

```bash
# Build with new version
docker build -t yourusername/easybacklog:v1.1.0 .

# Also tag as latest
docker tag yourusername/easybacklog:v1.1.0 yourusername/easybacklog:latest
```

### Step 2: Push Both Tags

```bash
docker push yourusername/easybacklog:v1.1.0
docker push yourusername/easybacklog:latest
```

### Step 3: Update Documentation

Update the CHANGELOG or README with the new version information.

---

## Automated Build Script for Maintainers

Create a script to automate the build and push process:

```bash
#!/bin/bash
# build-and-push.sh - Automate Docker Hub publishing

DOCKER_USERNAME="yourusername"  # Change this!
VERSION=${1:-"latest"}

echo "Building easyBacklog Docker image..."
docker build -t $DOCKER_USERNAME/easybacklog:$VERSION .

if [ $? -eq 0 ]; then
    echo "✓ Build successful"
    
    # Tag as latest if version specified
    if [ "$VERSION" != "latest" ]; then
        docker tag $DOCKER_USERNAME/easybacklog:$VERSION $DOCKER_USERNAME/easybacklog:latest
    fi
    
    echo "Pushing to Docker Hub..."
    docker push $DOCKER_USERNAME/easybacklog:$VERSION
    
    if [ "$VERSION" != "latest" ]; then
        docker push $DOCKER_USERNAME/easybacklog:latest
    fi
    
    echo "✅ Successfully published to Docker Hub!"
    echo "Image: $DOCKER_USERNAME/easybacklog:$VERSION"
else
    echo "❌ Build failed"
    exit 1
fi
```

**Usage:**
```bash
chmod +x build-and-push.sh
./build-and-push.sh v1.0.0  # Push version 1.0.0 and latest
./build-and-push.sh          # Push as latest only
```

---

## Automated Publishing with GitHub Actions (Optional)

For automatic builds on every commit, you can use GitHub Actions.

### Setup GitHub Actions

1. **Create Docker Hub Access Token**
   - Go to Docker Hub > Account Settings > Security
   - Click "New Access Token"
   - Name it "GitHub Actions" and copy the token

2. **Add GitHub Secrets**
   - Go to your GitHub repository > Settings > Secrets and variables > Actions
   - Click "New repository secret"
   - Add two secrets:
     - `DOCKER_HUB_USERNAME`: Your Docker Hub username
     - `DOCKER_HUB_TOKEN`: The access token from step 1

3. **Use the Workflow Template**
   - Copy `.github/workflows/docker-publish.yml.template` to `.github/workflows/docker-publish.yml`
   - Edit the file and replace `yourusername` with your Docker Hub username (appears 3 times)
   - Commit and push

4. **Verify It Works**
   - Go to GitHub repository > Actions tab
   - You should see the workflow running
   - Check Docker Hub after a few minutes to see your published image

### Workflow Behavior

- **Push to main:** Builds and pushes as `latest`
- **Push tag v1.0.0:** Builds and pushes as `v1.0.0`, `1.0`, and `latest`
- **Manual trigger:** Use GitHub Actions tab to trigger manually

### Benefits

- ✅ Automatic builds on every commit
- ✅ No need to build locally
- ✅ Students always get the latest version
- ✅ Version tagging support
- ✅ Build caching for faster builds

---

## Student/End User Instructions

Once images are published, students use the pre-built images:

### Quick Start for Students

```bash
# 1. Clone repository (for docker-compose file only)
git clone https://github.com/yourusername/easybacklog.git
cd easybacklog

# 2. Copy environment file
cp .env.example .env

# 3. Pull images and start (NO BUILDING REQUIRED!)
docker compose -f docker-compose.prebuilt.yml up -d

# 4. Initialize database (first time only)
docker compose -f docker-compose.prebuilt.yml exec web bundle exec rake db:schema:load
docker compose -f docker-compose.prebuilt.yml exec web bundle exec rake db:seed
docker compose -f docker-compose.prebuilt.yml exec web bundle exec rake db:seed:sample

# 5. Access at http://localhost:3000
```

**Time saved:** Students skip the 3-5 minute build process!

---

## Advanced: Using GitHub Actions for Automatic Builds

You can automate image building and publishing using GitHub Actions:

Create `.github/workflows/docker-publish.yml`:

```yaml
name: Publish Docker Image

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]
  workflow_dispatch:

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_HUB_USERNAME }}
          password: ${{ secrets.DOCKER_HUB_TOKEN }}
      
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v4
        with:
          images: yourusername/easybacklog
          tags: |
            type=ref,event=branch
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
      
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
```

**Setup:**
1. Go to Docker Hub → Account Settings → Security → New Access Token
2. Copy the token
3. Go to GitHub → Repository Settings → Secrets → New secret
4. Add `DOCKER_HUB_USERNAME` and `DOCKER_HUB_TOKEN`

Now images are automatically built and pushed on every commit to main!

---

## Docker Hub Repository Settings

### Recommended Settings

1. **Repository Visibility:** Public (free)
2. **Description:** "easyBacklog - Agile backlog management tool for learning Rails 3.2, Docker, and multi-tenant SaaS architecture"
3. **README:** Link to GitHub repository
4. **Tags:** 
   - `latest` - always points to most recent build
   - `v1.0.0`, `v1.1.0`, etc. - specific versions

### Repository URL

Your image will be available at:
```
https://hub.docker.com/r/yourusername/easybacklog
```

Students can see it in Docker Hub and trust it's the official image.

---

## Comparison: Build Locally vs Pull from Hub

| Aspect | Build Locally | Pull from Hub |
|--------|---------------|---------------|
| **Setup Time** | 5-10 minutes | 2-3 minutes |
| **Requirements** | Build tools, internet | Docker only |
| **Bandwidth** | ~300MB | ~800MB |
| **Consistency** | Varies by machine | Identical for all |
| **Disk Space** | ~1.5GB | ~1.5GB |
| **Best For** | Developers | Students |

---

## Troubleshooting

### "unauthorized: authentication required" when pushing

You need to login:
```bash
docker login
```

### "denied: requested access to the resource is denied"

The repository name doesn't match your username:
```bash
# Make sure you use YOUR username
docker build -t YOUR_USERNAME/easybacklog:latest .
```

### Image is too large (>1GB)

This is normal for Rails applications with all dependencies. To reduce size:
- Use multi-stage builds
- Remove unnecessary files
- Use Alpine-based Ruby images (complex for Rails 3.2)

### Students can't pull the image

Make sure:
1. Repository is public on Docker Hub
2. Image is actually pushed (check Docker Hub website)
3. Students use the exact image name

---

## Student Distribution Options

### Option 1: Docker Compose (Recommended)

**What students get:**
```bash
git clone https://github.com/yourusername/easybacklog.git
cd easybacklog
cp .env.example .env
docker compose -f docker-compose.prebuilt.yml up -d
# Setup database...
```

**Pros:** Full feature set (4 services)  
**Cons:** Need repository for compose file

### Option 2: Standalone Container

**What students get:**
```bash
docker pull yourusername/easybacklog:latest
docker run -p 3000:3000 yourusername/easybacklog:latest
```

**Pros:** Single command, no repository needed  
**Cons:** Only if using Dockerfile.standalone

### Option 3: Quick Start Script

Share a script that does everything:

```bash
#!/bin/bash
# student-quick-start.sh
git clone https://github.com/yourusername/easybacklog.git
cd easybacklog
cp .env.example .env
docker compose -f docker-compose.prebuilt.yml up -d
sleep 10
docker compose -f docker-compose.prebuilt.yml exec web bundle exec rake db:schema:load
docker compose -f docker-compose.prebuilt.yml exec web bundle exec rake db:seed
docker compose -f docker-compose.prebuilt.yml exec web bundle exec rake db:seed:sample
echo "✅ Ready! Open http://localhost:3000"
echo "Login: demo@example.com / password123"
```

---

## Example: Complete Workflow

### As Maintainer (You)

```bash
# 1. Build and tag
docker build -t mattanmr/easybacklog:latest .

# 2. Push to Docker Hub
docker push mattanmr/easybacklog:latest

# 3. Update docker-compose.prebuilt.yml
# Change 'yourusername' to 'mattanmr'

# 4. Commit and push
git add docker-compose.prebuilt.yml
git commit -m "Update to use mattanmr Docker Hub images"
git push
```

### As Student (End User)

```bash
# 1. Clone repository
git clone https://github.com/mattanmr/easybacklog.git
cd easybacklog

# 2. Copy environment
cp .env.example .env

# 3. Pull and start (NO BUILD - just pulls your pre-built image!)
docker compose -f docker-compose.prebuilt.yml up -d

# 4. Setup database
docker compose -f docker-compose.prebuilt.yml exec web bundle exec rake db:schema:load
docker compose -f docker-compose.prebuilt.yml exec web bundle exec rake db:seed
docker compose -f docker-compose.prebuilt.yml exec web bundle exec rake db:seed:sample

# 5. Access at http://localhost:3000
```

**Total time for student:** ~2-3 minutes (just pulling images, no building!)

---

## Summary

**For Maintainer:**
1. Build image: `docker build -t yourusername/easybacklog:latest .`
2. Push to hub: `docker push yourusername/easybacklog:latest`
3. Update `docker-compose.prebuilt.yml` with your username
4. Commit and share

**For Students:**
1. Clone repository (for compose file)
2. Run: `docker compose -f docker-compose.prebuilt.yml up -d`
3. Initialize database
4. Start using!

**Result:** Students get started in 2-3 minutes instead of 10+ minutes!

---

See also:
- **Docker Hub Documentation:** https://docs.docker.com/docker-hub/
- **Pushing Images Guide:** https://docs.docker.com/engine/reference/commandline/push/
