# Makefile for easyBacklog
# ==============================================================================
# This Makefile provides convenient shortcuts for common Docker operations.
# For students: Makefiles are a standard way to automate development tasks.
#
# Usage: make <target>
# Example: make start, make logs, make console
# ==============================================================================

.PHONY: help setup start stop restart logs console test clean reset status db-setup

# Default target - show help when running 'make' with no arguments
help:
	@echo "easyBacklog Docker Commands"
	@echo "==========================="
	@echo ""
	@echo "Setup & Start:"
	@echo "  make setup          - Initial setup (first time only)"
	@echo "  make setup-with-sample - Initial setup with demo data"
	@echo "  make start          - Start all services in background"
	@echo "  make stop           - Stop all services (keeps data)"
	@echo "  make restart        - Restart all services"
	@echo ""
	@echo "Development:"
	@echo "  make logs           - View logs from all services"
	@echo "  make logs-web       - View web server logs"
	@echo "  make logs-db        - View database logs"
	@echo "  make console        - Open Rails console"
	@echo "  make bash           - Open bash shell in web container"
	@echo "  make db-console     - Open PostgreSQL console"
	@echo ""
	@echo "Testing:"
	@echo "  make test           - Run RSpec tests"
	@echo "  make test-cucumber  - Run Cucumber integration tests"
	@echo ""
	@echo "Database:"
	@echo "  make db-setup       - Set up database (schema + seed)"
	@echo "  make db-seed-sample - Load sample demo data"
	@echo "  make db-reset       - Reset database (DELETES DATA)"
	@echo "  make db-seed        - Seed database with initial data"
	@echo ""
	@echo "Maintenance:"
	@echo "  make status         - Show running containers"
	@echo "  make clean          - Remove stopped containers"
	@echo "  make reset          - Complete reset (DELETES EVERYTHING)"
	@echo ""

# Initial Setup (run this first!)
setup:
	@echo "🚀 Setting up easyBacklog..."
	@if [ ! -f .env ]; then cp .env.example .env && echo "✓ Created .env file"; fi
	docker compose up -d --build
	@echo "⏳ Waiting for services to be ready..."
	@sleep 5
	docker compose exec web bundle exec rake db:schema:load
	docker compose exec web bundle exec rake db:seed
	@echo ""
	@echo "✅ Setup complete! Access at http://localhost:3000"
	@echo ""
	@echo "💡 Tip: Run 'make db-seed-sample' to load demo data (demo@example.com / password123)"

# Setup with sample data included
setup-with-sample:
	@echo "🚀 Setting up easyBacklog with sample data..."
	@if [ ! -f .env ]; then cp .env.example .env && echo "✓ Created .env file"; fi
	docker compose up -d --build
	@echo "⏳ Waiting for services to be ready..."
	@sleep 5
	docker compose exec web bundle exec rake db:schema:load
	docker compose exec web bundle exec rake db:seed
	docker compose exec web bundle exec rake db:seed:sample
	@echo ""
	@echo "✅ Setup complete! Access at http://localhost:3000"
	@echo "📧 Demo credentials: demo@example.com / password123"

# Start all services
start:
	@echo "🚀 Starting all services..."
	docker compose up -d
	@echo "✓ Services started. Access at http://localhost:3000"

# Stop all services (preserves data)
stop:
	@echo "🛑 Stopping services..."
	docker compose down
	@echo "✓ Services stopped"

# Restart services
restart:
	@echo "🔄 Restarting services..."
	docker compose restart
	@echo "✓ Services restarted"

# View logs from all services
logs:
	docker compose logs -f

# View web server logs only
logs-web:
	docker compose logs -f web

# View database logs only
logs-db:
	docker compose logs -f db

# View Sidekiq logs only
logs-sidekiq:
	docker compose logs -f sidekiq

# Open Rails console (interactive Ruby/Rails environment)
console:
	@echo "💻 Opening Rails console..."
	@echo "Tip: Try User.count, Account.all, or help"
	docker compose exec web bundle exec rails console

# Open bash shell in web container
bash:
	@echo "💻 Opening bash shell..."
	docker compose exec web bash

# Open PostgreSQL console
db-console:
	@echo "💾 Opening PostgreSQL console..."
	@echo "Tip: Try \\dt to list tables, \\d users to describe users table"
	docker compose exec db psql -U postgres -d easybacklog_development

# Run RSpec tests
test:
	@echo "🧪 Running RSpec tests..."
	docker compose exec web bundle exec rspec

# Run Cucumber integration tests
test-cucumber:
	@echo "🧪 Running Cucumber tests..."
	docker compose exec web bundle exec cucumber

# Set up database (load schema and seed data)
db-setup:
	@echo "💾 Setting up database..."
	docker compose exec web bundle exec rake db:schema:load
	docker compose exec web bundle exec rake db:seed
	@echo "✓ Database ready"

# Reset database (DELETES ALL DATA)
db-reset:
	@echo "⚠️  Resetting database (all data will be lost)..."
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker compose exec web bundle exec rake db:drop db:schema:load db:seed; \
		echo "✓ Database reset complete"; \
	else \
		echo "Cancelled"; \
	fi

# Seed database with initial data
db-seed:
	@echo "🌱 Seeding database..."
	docker compose exec web bundle exec rake db:seed
	@echo "✓ Database seeded"

# Load sample data for demo/learning
db-seed-sample:
	@echo "🌱 Loading sample data..."
	docker compose exec web bundle exec rake db:seed:sample
	@echo "✓ Sample data loaded"
	@echo "📧 Demo credentials: demo@example.com / password123"

# Show status of running containers
status:
	@echo "📊 Container Status:"
	@docker compose ps

# Remove stopped containers and unused images
clean:
	@echo "🧹 Cleaning up stopped containers..."
	docker compose rm -f
	@echo "🧹 Removing unused images..."
	docker image prune -f
	@echo "✓ Cleanup complete"

# Complete reset - removes everything including data
reset:
	@echo "⚠️  COMPLETE RESET - This will delete ALL data and images!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker compose down -v; \
		docker image rm easybacklog-web easybacklog-sidekiq 2>/dev/null || true; \
		echo "✓ Complete reset done. Run 'make setup' to start fresh."; \
	else \
		echo "Cancelled"; \
	fi

# Build or rebuild containers
build:
	@echo "🏗️  Building containers..."
	docker compose build
	@echo "✓ Build complete"

# Rebuild and restart
rebuild:
	@echo "🏗️  Rebuilding and restarting..."
	docker compose down
	docker compose up -d --build
	@echo "✓ Rebuild complete"

# Install gems (after Gemfile changes)
bundle-install:
	@echo "📦 Installing gems..."
	docker compose exec web bundle install
	docker compose restart web sidekiq
	@echo "✓ Gems installed and services restarted"
