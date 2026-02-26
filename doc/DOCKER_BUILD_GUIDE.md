# Docker Build & Publish Guide

This guide is for maintainers who want to build the easyBacklog Docker image and publish it to Docker Hub (or another registry).

## Prerequisites

- Docker installed and running
- Docker Hub account (or other container registry account)
- `docker` CLI authenticated: `docker login`

## Building the Docker Image

### Build for local development/testing:

```bash
# Build with default tag
docker build -t easybacklog:latest .

# Or with specific version tag
docker build -t easybacklog:v1.0.0 .
```

### Build for multiple architectures (optional, for cross-platform support):

```bash
# Requires Docker buildx (usually pre-installed)
docker buildx build --platform linux/amd64,linux/arm64 \
  -t yourusername/easybacklog:latest \
  -t yourusername/easybacklog:v1.0.0 \
  --push .
```

## Tagging the Image

Before publishing, tag your image with your Docker Hub username:

```bash
# Tag for Docker Hub
docker tag easybacklog:latest yourusername/easybacklog:latest
docker tag easybacklog:latest yourusername/easybacklog:v1.0.0

# Or during build:
docker build -t yourusername/easybacklog:latest .
```

Replace `yourusername` with your actual Docker Hub username.

## Publishing to Docker Hub

### Push to Docker Hub:

```bash
# Push latest tag
docker push yourusername/easybacklog:latest

# Push version tag
docker push yourusername/easybacklog:v1.0.0

# Push all tags at once
docker push yourusername/easybacklog --all-tags
```

### Verify published image:

Visit `https://hub.docker.com/r/yourusername/easybacklog` to see your published image and tags.

## Publishing to Other Registries

### GitHub Container Registry (GHCR):

```bash
# Authenticate
echo $GH_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Tag
docker tag easybacklog:latest ghcr.io/username/easybacklog:latest

# Push
docker push ghcr.io/username/easybacklog:latest
```

### AWS ECR:

```bash
# Create repository (if not exists)
aws ecr create-repository --repository-name easybacklog

# Get login token
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account>.dkr.ecr.<region>.amazonaws.com

# Tag and push
docker tag easybacklog:latest <account>.dkr.ecr.us-east-1.amazonaws.com/easybacklog:latest
docker push <account>.dkr.ecr.us-east-1.amazonaws.com/easybacklog:latest
```

## Local Testing Before Publishing

### Test the image locally:

```bash
# Create a test directory
mkdir easybacklog-test && cd easybacklog-test

# Copy the example compose file
cp ../docker-compose.example.yml docker-compose.yml

# Copy and configure .env
cp ../.env.example .env

# Update docker-compose.yml to use your test image
# Change: image: ${DOCKER_IMAGE:-mattanmr/easybacklog:latest}
# To: image: yourusername/easybacklog:latest

# Run with local-built image  
docker-compose up -d

# Test
curl http://localhost:3000

# Cleanup
docker-compose down -v
```

## Automating with CI/CD

### GitHub Actions Example:

Create `.github/workflows/docker-publish.yml`:

```yaml
name: Publish Docker Image

on:
  push:
    tags:
      - 'v*'

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v1
      
      - name: Login to Docker Hub
        uses: docker/login-action@v1
        with:
          username: ${{ secrets.DOCKER_HUB_USERNAME }}
          password: ${{ secrets.DOCKER_HUB_TOKEN }}
      
      - name: Build and push
        uses: docker/build-push-action@v2
        with:
          context: .
          push: true
          tags: |
            ${{ secrets.DOCKER_HUB_USERNAME }}/easybacklog:latest
            ${{ secrets.DOCKER_HUB_USERNAME }}/easybacklog:${{ github.ref_name }}
          platforms: linux/amd64,linux/arm64
```

## Docker Image Optimization

### Current Dockerfile notes:

- Uses `ruby:2.6.10-bullseye` for Rails 3.2 compatibility
- Installs dependencies in order of change frequency (stable → frequently changing)
- Uses `--no-install-recommends` to minimize image size
- Caches gem layer for faster rebuilds

### To reduce image size further:

1. Use multi-stage builds (separate build and runtime stages)
2. Clean up package manager caches (`apt-get clean`)
3. Remove unnecessary gems from production group
4. Consider Alpine Linux base (may have compatibility issues with Rails 3.2)

### Example multi-stage optimization:

```dockerfile
# Build stage
FROM ruby:2.6.10-bullseye AS builder

# ... install dependencies and gems ...

# Runtime stage
FROM ruby:2.6.10-bullseye

# Copy only necessary files from builder
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY . /app

# ... rest of setup ...
```

## Versioning Strategy

Recommend semantic versioning:

- `latest` → Most recent stable release
- `v1.0.0` → Specific version tags
- `develop` → Development/testing versions (optional)

Tag releases in git:

```bash
git tag -a v1.0.0 -m "Version 1.0.0 - Docker Hub ready"
git push origin v1.0.0
```

## Cleanup & Maintenance

### Remove old images:

```bash
# List images
docker images | grep easybacklog

# Remove local image
docker rmi yourusername/easybacklog:old-tag

# Remove from Docker Hub (via web UI: hub.docker.com)
```

### Docker Hub settings:

1. Go to hub.docker.com/r/yourusername/easybacklog
2. Settings → Repository Visibility (Public/Private)
3. Settings → Build Rules (configure automated builds if desired)

## Troubleshooting

### Image won't build:

```bash
# Check Dockerfile syntax
docker build --no-cache -t test .

# See full build output
docker build --progress=plain .
```

### Push fails:

```bash
# Verify authentication
docker login

# Check image name format
docker images | grep easybacklog

# Verify tag exists
docker image inspect yourusername/easybacklog:latest
```

### Image runs but app fails:

```bash
# Check logs
docker logs <container_id>

# Run with debug shell
docker run -it yourusername/easybacklog:latest /bin/bash

# Test inside container
bundle exec rails console
```

## Resources

- [Docker Hub Docs](https://docs.docker.com/docker-hub/)
- [Docker Build Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Buildx Multi-Platform Guide](https://docs.docker.com/buildx/working-with-buildx/)
