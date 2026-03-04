#!/bin/bash
# Build and Push Script for Docker Hub
# ==============================================================================
# This script builds the easyBacklog Docker image and pushes it to Docker Hub.
# Maintainers use this to create pre-built images for students to pull.
#
# Prerequisites:
#   1. Docker Hub account
#   2. Logged in with: docker login
#
# Usage:
#   ./build-and-push.sh [version]
#
# Examples:
#   ./build-and-push.sh           # Push as 'latest'
#   ./build-and-push.sh v1.0.0    # Push as 'v1.0.0' and 'latest'
# ==============================================================================

set -e

# Configuration - CHANGE THIS TO YOUR DOCKER HUB USERNAME
DOCKER_USERNAME="${DOCKER_USERNAME:-yourusername}"

if [ "$DOCKER_USERNAME" = "yourusername" ]; then
    echo "⚠️  Warning: DOCKER_USERNAME is set to 'yourusername'"
    echo ""
    echo "Please set your Docker Hub username:"
    echo "  export DOCKER_USERNAME=your-actual-username"
    echo "  ./build-and-push.sh"
    echo ""
    echo "Or edit this script and change DOCKER_USERNAME at the top."
    exit 1
fi

VERSION=${1:-"latest"}
IMAGE_NAME="$DOCKER_USERNAME/easybacklog"

echo "🐳 Building and Pushing easyBacklog to Docker Hub"
echo "=================================================="
echo ""
echo "Image: $IMAGE_NAME:$VERSION"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running"
    echo "Please start Docker Desktop and try again."
    exit 1
fi

echo "✓ Docker is running"
echo ""

# Check if logged in to Docker Hub
if ! docker info 2>/dev/null | grep -q "Username:"; then
    echo "⚠️  You may not be logged in to Docker Hub"
    echo ""
    read -p "Do you want to login now? [Y/n] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        docker login
    else
        echo "Please login with: docker login"
        exit 1
    fi
fi

echo "✓ Logged in to Docker Hub"
echo ""

# Build the image
echo "📦 Building Docker image..."
echo "This will take 3-5 minutes..."
echo ""

if docker build -t $IMAGE_NAME:$VERSION .; then
    echo ""
    echo "✅ Build successful!"
    echo ""
else
    echo ""
    echo "❌ Build failed"
    exit 1
fi

# Tag as latest if version is specified
if [ "$VERSION" != "latest" ]; then
    echo "🏷️  Tagging as latest..."
    docker tag $IMAGE_NAME:$VERSION $IMAGE_NAME:latest
    echo "✓ Tagged as latest"
    echo ""
fi

# Push to Docker Hub
echo "📤 Pushing to Docker Hub..."
echo "This will take 5-10 minutes..."
echo ""

if docker push $IMAGE_NAME:$VERSION; then
    echo ""
    echo "✅ Pushed $IMAGE_NAME:$VERSION"
else
    echo ""
    echo "❌ Push failed for $IMAGE_NAME:$VERSION"
    exit 1
fi

# Push latest tag if version was specified
if [ "$VERSION" != "latest" ]; then
    if docker push $IMAGE_NAME:latest; then
        echo "✅ Pushed $IMAGE_NAME:latest"
    else
        echo "❌ Push failed for $IMAGE_NAME:latest"
        exit 1
    fi
fi

echo ""
echo "======================================"
echo "✅ Successfully published to Docker Hub!"
echo "======================================"
echo ""
echo "Image: $IMAGE_NAME:$VERSION"
echo "Docker Hub: https://hub.docker.com/r/$DOCKER_USERNAME/easybacklog"
echo ""
echo "Students can now pull and run with:"
echo "  docker pull $IMAGE_NAME:$VERSION"
echo ""
echo "Or use Docker Compose:"
echo "  docker compose -f docker-compose.prebuilt.yml up -d"
echo ""
echo "Next steps:"
echo "  1. Update docker-compose.prebuilt.yml with your username (if not done)"
echo "  2. Test the image: docker run -p 3000:3000 $IMAGE_NAME:$VERSION"
echo "  3. Share instructions with students"
echo ""
