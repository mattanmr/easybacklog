#!/bin/bash
# Quick Start Script for easyBacklog Standalone Docker Image
# ==============================================================================
# This script builds and runs the standalone Docker image with a single command.
#
# Usage: ./quick-start.sh
# ==============================================================================

set -e

echo "🚀 easyBacklog Quick Start"
echo "============================"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed"
    echo ""
    echo "Please install Docker Desktop:"
    echo "  Mac: https://docs.docker.com/desktop/install/mac-install/"
    echo "  Windows: https://docs.docker.com/desktop/install/windows-install/"
    echo "  Linux: https://docs.docker.com/desktop/install/linux-install/"
    exit 1
fi

echo "✓ Docker is installed"
echo ""

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "❌ Error: Docker is not running"
    echo ""
    echo "Please start Docker Desktop and try again."
    exit 1
fi

echo "✓ Docker is running"
echo ""

# Build the image
echo "📦 Building Docker image..."
echo "This may take 5-10 minutes on first run..."
echo ""

if docker build -f Dockerfile.standalone -t easybacklog:latest .; then
    echo ""
    echo "✅ Image built successfully!"
    echo ""
else
    echo ""
    echo "❌ Error: Failed to build image"
    exit 1
fi

# Run the container
echo "🚀 Starting container..."
echo ""

# Stop and remove any existing container
docker rm -f easybacklog 2>/dev/null || true

# Run the new container
if docker run -d -p 3000:3000 --name easybacklog easybacklog:latest; then
    echo "✅ Container started successfully!"
    echo ""
    echo "⏳ Waiting for application to initialize (30 seconds)..."
    echo ""
    
    # Wait for the application to be ready
    sleep 30
    
    echo "============================"
    echo "✅ easyBacklog is ready!"
    echo "============================"
    echo ""
    echo "🌐 Open your browser to: http://localhost:3000"
    echo ""
    echo "📧 Demo account credentials:"
    echo "   Email:    demo@example.com"
    echo "   Password: password123"
    echo ""
    echo "Useful commands:"
    echo "  View logs:    docker logs -f easybacklog"
    echo "  Stop:         docker stop easybacklog"
    echo "  Start again:  docker start easybacklog"
    echo "  Remove:       docker rm -f easybacklog"
    echo ""
else
    echo ""
    echo "❌ Error: Failed to start container"
    exit 1
fi
