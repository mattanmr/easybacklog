# Getting Started with easyBacklog

Welcome! This guide will help you get easyBacklog running on your local machine and teach you about its architecture.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Understanding the Architecture](#understanding-the-architecture)
4. [Exploring the Codebase](#exploring-the-codebase)
5. [Common Tasks](#common-tasks)
6. [Learning Paths](#learning-paths)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

You only need Docker installed on your machine:

- **Docker Desktop** (recommended) - [Download here](https://www.docker.com/products/docker-desktop)
  - Mac: Docker Desktop for Mac
  - Windows: Docker Desktop for Windows (with WSL2)
  - Linux: Docker Engine + Docker Compose plugin

To verify installation:
```bash
docker --version        # Should show v20.x or higher
docker compose version  # Should show v2.x or higher
```

**That's it!** You don't need Ruby, PostgreSQL, Redis, or any other dependencies installed locally. Docker handles everything.

---

## Quick Start

### Step 1: Clone the Repository

```bash
git clone https://github.com/mattanmr/easybacklog.git
cd easybacklog
```

### Step 2: Set Up Environment Variables

```bash
cp .env.example .env
```

The default `.env` works for local development. The application will run without external services like SendGrid or Ably.

### Step 3: Start the Application

```bash
docker compose up -d
```

This command:
- Downloads required Docker images (first time only, ~5 minutes)
- Builds the easyBacklog application image (~3 minutes first time)
- Starts 4 services: PostgreSQL, Redis, Web Server, and Sidekiq

**Pro tip:** Remove the `-d` flag to see logs in real-time: `docker compose up`

### Step 4: Initialize the Database

```bash
# Load the database schema
docker compose exec web bundle exec rake db:schema:load

# Seed initial data (locales, configurations)
docker compose exec web bundle exec rake db:seed
```

**Note:** We use `db:schema:load` instead of `db:migrate` because the old migrations have compatibility issues with modern Ruby gems. The schema file is the source of truth.

### Step 5: Access the Application

Open your browser to **http://localhost:3000**

You should see the easyBacklog homepage! 🎉

---

## Understanding the Architecture

easyBacklog follows a standard Rails MVC (Model-View-Controller) architecture with some additional components.

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Your Browser                         │
│                     http://localhost:3000                    │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                      Web Server (Thin)                       │
│                      Rails Application                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Controllers  ← Routes → Views (HAML/EJS)           │   │
│  │      ↕                         ↕                     │   │
│  │  Models (ActiveRecord) → JavaScript (Backbone.js)   │   │
│  └─────────────────────────────────────────────────────┘   │
└───────┬────────────────────────────────┬────────────────────┘
        │                                │
        ▼                                ▼
┌───────────────────┐          ┌────────────────────┐
│   PostgreSQL 11   │          │   Redis 5          │
│   (Database)      │          │   (Cache/Jobs)     │
│   Port: 5432      │          │   Port: 6379       │
└───────────────────┘          └────────┬───────────┘
                                        │
                                        ▼
                            ┌────────────────────────┐
                            │   Sidekiq Worker       │
                            │   (Background Jobs)    │
                            └────────────────────────┘
```

### Key Components

| Component | Technology | Purpose | Port |
|-----------|-----------|---------|------|
| **Web Server** | Thin/Rails 3.2 | Handles HTTP requests, serves pages | 3000 |
| **Database** | PostgreSQL 11 | Stores all application data | 5432 |
| **Cache/Queue** | Redis 5 | Caches data, queues background jobs | 6379 |
| **Background Jobs** | Sidekiq | Processes async tasks (emails, reports) | N/A |
| **Frontend** | Backbone.js/jQuery | Interactive UI components | N/A |

---

## Exploring the Codebase

### Directory Structure

```
easybacklog/
├── app/                      # Main application code
│   ├── controllers/          # Handle HTTP requests (28+ controllers)
│   ├── models/              # Data models (ActiveRecord)
│   ├── views/               # HTML templates (HAML)
│   ├── assets/              # CSS, JavaScript, images
│   ├── helpers/             # View helper methods
│   ├── mailers/             # Email templates and logic
│   └── workers/             # Sidekiq background job workers
│
├── config/                   # Application configuration
│   ├── routes.rb            # URL routing definitions
│   ├── database.yml         # Database configuration
│   ├── environments/        # Environment-specific settings
│   └── initializers/        # Gem and app initialization
│
├── db/                      # Database files
│   ├── schema.rb            # Database schema (source of truth)
│   ├── seeds.rb             # Initial data seeding
│   └── migrate/             # Historical migrations
│
├── spec/                    # RSpec unit tests
├── features/                # Cucumber integration tests
│
├── public/                  # Static files (images, stylesheets)
├── lib/                     # Custom libraries
└── doc/                     # Documentation (you are here!)
```

### Important Files to Know

| File | Purpose |
|------|---------|
| `Dockerfile` | Defines how to build the application image |
| `docker-compose.yml` | Defines all services and how they connect |
| `.env.example` | Template for environment variables |
| `config/routes.rb` | Maps URLs to controllers |
| `db/schema.rb` | Database structure definition |
| `Gemfile` | Ruby dependencies |

---

## Common Tasks

### Viewing Logs

```bash
# All services
docker compose logs -f

# Just the web server
docker compose logs -f web

# Just Sidekiq (background jobs)
docker compose logs -f sidekiq

# Search for errors
docker compose logs web | grep -i error
```

### Accessing the Rails Console

The Rails console lets you interact with the application interactively:

```bash
docker compose exec web bundle exec rails console
```

**Try these commands:**
```ruby
# Count users
User.count

# List all accounts
Account.all.limit(5)

# Find the first user
user = User.first

# Create a new user
User.create!(
  email: "student@example.com",
  password: "password123",
  password_confirmation: "password123"
)
```

Type `exit` to leave the console.

### Running Tests

```bash
# Run RSpec tests (unit tests)
docker compose exec web bundle exec rspec

# Run specific test file
docker compose exec web bundle exec rspec spec/models/user_spec.rb

# Run Cucumber tests (integration tests)
docker compose exec web bundle exec cucumber

# Run specific feature
docker compose exec web bundle exec cucumber features/user_login.feature
```

### Database Operations

```bash
# Access PostgreSQL console
docker compose exec db psql -U postgres -d easybacklog_development

# Inside psql, try:
\dt              # List all tables
\d users         # Describe users table
SELECT * FROM users LIMIT 5;
\q               # Quit

# Reset database (DELETES ALL DATA)
docker compose exec web bundle exec rake db:drop db:schema:load db:seed
```

### Stopping and Starting

```bash
# Stop all services (keeps data)
docker compose down

# Start all services
docker compose up -d

# Restart just the web server (after code changes)
docker compose restart web

# View running containers
docker compose ps

# Remove everything including data
docker compose down -v
```

---

## Learning Paths

Choose a path based on your learning goals:

### 🎯 Path 1: Learn Rails Architecture (Beginner)

1. **Start with Routes** - Open `config/routes.rb`
   - See how URLs map to controllers
   - Find the route for the homepage (`root to: '...'`)

2. **Follow a Request** - Pick a route and follow it:
   ```
   URL (routes.rb) → Controller (app/controllers/) → 
   View (app/views/) → Browser
   ```

3. **Explore Models** - Look at `app/models/user.rb`
   - See how models relate to database tables
   - Check associations (`has_many`, `belongs_to`)

4. **Experiment in Console**:
   ```bash
   docker compose exec web bundle exec rails console
   ```

### 🚀 Path 2: Learn Docker & Containerization (Intermediate)

1. **Study the Dockerfile**
   - See how the Ruby environment is built
   - Understand layer caching

2. **Explore docker-compose.yml**
   - Learn service orchestration
   - Understand networking between containers

3. **Experiment with Services**:
   ```bash
   # Stop just the web server
   docker compose stop web
   
   # Start it again
   docker compose start web
   
   # View resource usage
   docker stats
   ```

4. **Modify Configuration**
   - Try changing port mappings
   - Add volume mounts
   - Experiment with environment variables

### 💼 Path 3: Learn Multi-Tenant SaaS (Advanced)

1. **Study the Account Model** - `app/models/account.rb`
   - How data is scoped per account
   - Tenant isolation strategies

2. **Review Authentication** - `doc/AUTHENTICATION_DEEP_DIVE.md`
   - Devise integration
   - Session management

3. **Explore Background Jobs** - `app/workers/`
   - How Sidekiq processes async tasks
   - Job retry strategies

4. **API Design** - Look at API controllers
   - RESTful design patterns
   - JSON response formatting

### 🧪 Path 4: Learn Testing (Intermediate)

1. **Read Existing Tests** - `spec/models/user_spec.rb`
   - RSpec syntax and matchers
   - Test structure (describe, context, it)

2. **Run Tests**:
   ```bash
   docker compose exec web bundle exec rspec spec/models/
   ```

3. **Write a Simple Test** - Add a test to `spec/models/user_spec.rb`

4. **Integration Testing** - Check `features/` directory
   - Cucumber feature files (plain English)
   - Step definitions

---

## Troubleshooting

### Problem: Containers won't start

```bash
# Check what's running
docker compose ps

# Check logs for errors
docker compose logs

# Common fix: remove and rebuild
docker compose down -v
docker compose up -d --build
```

### Problem: "Port already in use"

Another application is using port 3000, 5432, or 6379.

**Solution 1:** Stop the other application

**Solution 2:** Change ports in `docker-compose.yml`:
```yaml
ports:
  - "3001:3000"  # Use port 3001 instead
```

### Problem: "Database doesn't exist"

```bash
# Create and set up the database
docker compose exec web bundle exec rake db:schema:load db:seed
```

### Problem: "Bundle install errors"

```bash
# Rebuild the container
docker compose down
docker compose up -d --build
```

### Problem: "Gem missing" errors

```bash
# Install gems
docker compose exec web bundle install

# Restart services
docker compose restart web sidekiq
```

### Problem: Can't access http://localhost:3000

1. Check if web server is running:
   ```bash
   docker compose ps
   ```

2. Check web server logs:
   ```bash
   docker compose logs web
   ```

3. Try accessing directly:
   ```bash
   curl http://localhost:3000
   ```

### Still Stuck?

- Check the [Docker Operations Guide](DOCKER_GUIDE.md) for detailed commands
- Review [Local Development Guide](LOCAL_DEVELOPMENT_GUIDE.md) for setup details
- Look for similar error messages in the logs

---

## Next Steps

Once you have the application running:

1. ✅ **Create an account** - Sign up at http://localhost:3000/users/sign_up
2. ✅ **Create a backlog** - Experience the core functionality
3. ✅ **Explore the code** - Follow one of the learning paths above
4. ✅ **Run the tests** - See how the application is tested
5. ✅ **Make changes** - Try modifying views or adding features
6. ✅ **Read the docs** - Check the `doc/` directory for more guides

---

## Additional Resources

- [Docker Operations Guide](DOCKER_GUIDE.md) - Comprehensive Docker commands
- [Local Development Guide](LOCAL_DEVELOPMENT_GUIDE.md) - Detailed setup and status
- [Authentication Deep Dive](AUTHENTICATION_DEEP_DIVE.md) - How auth works
- [External Services Guide](EXTERNAL_SERVICES_GUIDE.md) - SendGrid, Ably setup

---

## Contributing

This is an archived open-source project. Feel free to:
- Fork it and experiment
- Use it for learning
- Build upon it for your own projects

The codebase is under the [MIT License](../LICENSE), so you're free to use it however you like!

---

**Happy Learning! 🚀**

If you get stuck or have questions, check the documentation files in the `doc/` directory or review the Docker logs for clues.
