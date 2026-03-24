# easyBacklog

easyBacklog is an intuitive time saving backlog management tool for Agile practitioners working in or with agencies. It is designed to be not just another all purpose project management, Agile or collaboration tool for teams. It was a free service available to practitioners at easybacklog.com.

## Home page for posterity

![easyBacklog.com home page as at Aug 2022](public/home-screenshot.png)

# 🐳 Quick Start with Docker

**New to Docker or easyBacklog?** → Start with [REMOTE_USER_GUIDE.md](doc/REMOTE_USER_GUIDE.md) - our simplest guide!

Choose your preferred approach:

## Option 1: Pre-Built Images from Docker Hub (Fastest!)

If the maintainer has published images to Docker Hub, you can skip building entirely:

```bash
# Automated setup (1 command)
./quick-start-prebuilt.sh
```

**Time:** ~2-3 minutes (just pulls images, no building!)

📖 **See [DOCKER_HUB_PUBLISHING.md](doc/DOCKER_HUB_PUBLISHING.md)** - For maintainers who want to publish images

## Option 2: Standalone Docker Image (Build Locally - 2 Commands)

Perfect for students who want a self-contained setup:

### Automated Quick Start (1 Command)
```bash
./quick-start.sh
```

This script builds the image and starts the container automatically!

### Manual Build and Run (2 Commands)
```bash
# 1. Build the image
docker build -f Dockerfile.standalone -t easybacklog:latest .

# 2. Run the container
docker run -p 3000:3000 easybacklog:latest
```

Open http://localhost:3000 and login with `demo@example.com` / `password123`

📖 **See [STANDALONE_DOCKER_IMAGE.md](doc/STANDALONE_DOCKER_IMAGE.md) for detailed instructions**

## Option 3: Docker Compose (Full Development Setup)

Best for learning about microservices architecture:

### Automated Quick Start (1 Command)
```bash
./quick-start-compose.sh
```

This script automatically sets up everything including sample data!

### Manual Setup Using Makefile (1 Command)
```bash
make setup
```

### Manual Setup with Docker Compose (4 Commands)
```bash
# 1. Copy environment configuration
cp .env.example .env

# 2. Start all services (database, Redis, web server, background jobs)
docker compose up -d

# 3. Set up the database
docker compose exec web bundle exec rake db:schema:load
docker compose exec web bundle exec rake db:seed

# 4. Open your browser
open http://localhost:3000
```

**That's it!** 🎉 You now have a fully functional easyBacklog instance running.

### What's Running?

- **Web Application**: http://localhost:3000 (Rails app)
- **PostgreSQL Database**: Port 5432 (data persistence)
- **Redis**: Port 6379 (background jobs)
- **Sidekiq**: Background job processor

### Useful Commands

```bash
# View logs
docker compose logs -f web

# Access Rails console
docker compose exec web bundle exec rails console

# Run tests
docker compose exec web bundle exec rspec
docker compose exec web bundle exec cucumber

# Stop services
docker compose down

# Reset everything (removes all data)
docker compose down -v
```

📚 **For more details, see [DOCKER_GUIDE.md](doc/DOCKER_GUIDE.md), [GETTING_STARTED.md](doc/GETTING_STARTED.md), [QUICKSTART.md](QUICKSTART.md), and [DOCKER_BUILD_GUIDE.md](doc/DOCKER_BUILD_GUIDE.md)**

---

# End of life: Q3 2022

The free easyBacklog.com service shut down on 30 September 2022. When [Matthew O'Riordan](https://mattheworiordan.com) started easyBacklog, his goals were modest and straightforward, he wanted to give people an intuitive time saving backlog management tool for Agile practitioners working in or with agencies. Before it shut, nearly 400k backlogs were created by more than 55k people.

easyBacklog was shut down because the project was neglected for many years. [Matthew O'Riordan](https://mattheworiordan.com) is running [Ably](https://ably.com), a business of 150 people that he founded to provide [serverless websockets](https://ably.com/topic/websockets) and [realtime collaborative APIs](https://ably.com/features) to developers. Ably as of 2022 powers realtime experiences for more than 300 million people each month.

# License (now open source)

This project has now been open sourced under the [MIT license](./LICENSE). Anyone is free to use this software and modify it as they see fit.

# Technology Stack

easyBacklog is built on [Ruby on Rails](https://rubyonrails.org/) and has not been materially updated since 2015. This makes it an excellent learning resource for understanding legacy Rails applications and how to containerize them.

**Components:**
* Ruby on Rails 3.2 (legacy, from 2015)
* PostgreSQL 11 database
* jQuery and Backbone.js for frontend
* Devise for authentication
* HAML and EJS for templates
* Sidekiq for background jobs
* Redis for job queuing
* [Ably for realtime collaboration](https://ably.com)

**Learning Value:** This codebase demonstrates a complete, production-grade Rails 3.2 application with multi-tenancy, background jobs, real-time features, PDF generation, and a RESTful API. It's perfect for students learning about:
- Legacy Rails application architecture
- Containerization with Docker
- Background job processing
- Multi-tenant SaaS patterns
- Authentication and authorization
- API design

---

# For Students: Where to Start

This repository is fully dockerized and ready for experimentation. Here's your learning path:

## 📚 Documentation

Start with these guides in order:

1. **[GETTING_STARTED.md](doc/GETTING_STARTED.md)** - Complete beginner's guide with learning paths
2. **[DOCKER_GUIDE.md](doc/DOCKER_GUIDE.md)** - Comprehensive Docker operations reference
3. **[LOCAL_DEVELOPMENT_GUIDE.md](doc/LOCAL_DEVELOPMENT_GUIDE.md)** - Development environment details
4. **[AUTHENTICATION_DEEP_DIVE.md](doc/AUTHENTICATION_DEEP_DIVE.md)** - How authentication works

## 🎯 Quick Learning Exercises

### Exercise 1: Get It Running (15 minutes)
```bash
# 1. Start the application
docker compose up -d

# 2. Set up the database
docker compose exec web bundle exec rake db:schema:load db:seed

# 3. Load sample data
docker compose exec web bundle exec rake db:seed:sample

# 4. Visit http://localhost:3000
# 5. Log in with: demo@example.com / password123
```

### Exercise 2: Explore the Code (30 minutes)
- Look at `config/routes.rb` - See how URLs map to controllers
- Open `app/models/user.rb` - Understand the User model
- Check `app/controllers/backlogs_controller.rb` - See CRUD operations
- Review `app/views/backlogs/` - Explore HAML templates

### Exercise 3: Make Your First Change (1 hour)
- Add a new field to the homepage
- Create a new route and controller action
- Modify a view template
- Run tests with `docker compose exec web bundle exec rspec`

### Exercise 4: Understand Architecture (2 hours)
- Study how Devise handles authentication
- Explore how Sidekiq processes background jobs
- Learn how multi-tenancy works with Account model
- Examine the Backbone.js frontend code

## 🛠️ Useful Commands

```bash
# Access Rails console for live experimentation
make console

# View application logs
make logs

# Run tests
make test

# Access database console
make db-console

# Reset everything and start fresh
make reset
```

## 💡 Learning Resources

- **Rails 3.2 Guides**: [guides.rubyonrails.org](https://guides.rubyonrails.org/v3.2/)
- **Devise Authentication**: [github.com/heartcombo/devise](https://github.com/heartcombo/devise)
- **Docker Documentation**: [docs.docker.com](https://docs.docker.com/)
- **Sidekiq Background Jobs**: [github.com/mperham/sidekiq](https://github.com/mperham/sidekiq)

---