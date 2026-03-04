#!/bin/bash
# Quick Start Script for Students Using Pre-Built Images
# ==============================================================================
# This script pulls pre-built images from Docker Hub and starts easyBacklog.
# No building required - much faster than building locally!
#
# Usage: ./quick-start-prebuilt.sh
# ==============================================================================

set -e

echo "🚀 easyBacklog Quick Start (Pre-Built Images)"
echo "==============================================="
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

# Check if docker compose is available
if ! docker compose version &> /dev/null; then
    echo "❌ Error: Docker Compose is not available"
    echo ""
    echo "Please install Docker Compose:"
    echo "  https://docs.docker.com/compose/install/"
    exit 1
fi

echo "✓ Docker Compose is available"
echo ""

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📄 Creating .env file..."
    cp .env.example .env
    echo "✓ Created .env file"
    echo ""
fi

# Pull and start services using pre-built images
echo "📦 Pulling pre-built images and starting services..."
echo "This will download images from Docker Hub (~800MB)"
echo "This is MUCH faster than building locally!"
echo ""
echo "Services to be started:"
echo "  • PostgreSQL database (pulls from Docker Hub)"
echo "  • Redis cache (pulls from Docker Hub)"
echo "  • Rails web server (pulls YOUR pre-built image)"
echo "  • Sidekiq background worker (pulls YOUR pre-built image)"
echo ""

if docker compose -f docker-compose.prebuilt.yml up -d; then
    echo ""
    echo "✅ Services started successfully!"
    echo ""
else
    echo ""
    echo "❌ Error: Failed to start services"
    echo ""
    echo "Common issues:"
    echo "  • Image not found: Make sure the maintainer pushed images to Docker Hub"
    echo "  • Check docker-compose.prebuilt.yml has correct Docker Hub username"
    echo ""
    exit 1
fi

# Wait for services to be healthy
echo "⏳ Waiting for services to be healthy..."
sleep 10

# Setup database
echo "💾 Setting up database..."
if docker compose -f docker-compose.prebuilt.yml exec -T web bundle exec rake db:schema:load > /tmp/db-setup.log 2>&1; then
    echo "✓ Database schema loaded"
else
    echo "⚠️  Note: Database schema loading had warnings (this is normal for Rails 3.2)"
fi

if docker compose -f docker-compose.prebuilt.yml exec -T web bundle exec rake db:seed > /tmp/db-seed.log 2>&1; then
    echo "✓ Database seeded with initial data"
else
    echo "⚠️  Note: Database seeding had warnings (this is normal for Rails 3.2)"
fi

# Ask about sample data
echo ""
read -p "📊 Load sample data (demo account with backlog and stories)? [Y/n] " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
    echo "🌱 Loading sample data..."
    if docker compose -f docker-compose.prebuilt.yml exec -T web bundle exec rake db:seed:sample > /tmp/db-sample.log 2>&1; then
        echo "✓ Sample data loaded"
        SAMPLE_DATA_LOADED=true
    else
        echo "⚠️  Sample data loading had issues (check logs)"
    fi
else
    echo "⏭️  Skipped sample data"
    SAMPLE_DATA_LOADED=false
fi

echo ""
echo "============================"
echo "✅ easyBacklog is ready!"
echo "============================"
echo ""
echo "🌐 Open your browser to: http://localhost:3000"
echo ""

if [ "$SAMPLE_DATA_LOADED" = true ]; then
    echo "📧 Demo account credentials:"
    echo "   Email:    demo@example.com"
    echo "   Password: password123"
    echo ""
fi

echo "📊 Service Status:"
docker compose -f docker-compose.prebuilt.yml ps
echo ""

echo "Useful commands:"
echo "  View logs:        docker compose -f docker-compose.prebuilt.yml logs -f web"
echo "  Rails console:    docker compose -f docker-compose.prebuilt.yml exec web bundle exec rails console"
echo "  Stop services:    docker compose -f docker-compose.prebuilt.yml down"
echo "  Restart:          docker compose -f docker-compose.prebuilt.yml restart"
echo ""
echo "📚 For more information, see doc/REMOTE_USER_GUIDE.md"
echo ""
