# easyBacklog

easyBacklog is an intuitive time saving backlog management tool for Agile practitioners working in or with agencies. It is designed to be not just another all purpose project management, Agile or collaboration tool for teams. It was a free service available to practitioners at easybacklog.com.

## Home page for posterity

![easyBacklog.com home page as at Aug 2022](public/home-screenshot.png)

# 🐳 Quick Start with Docker (Recommended for Learning)

Get started with easyBacklog in minutes using Docker:

```bash
# 1. Clone the repository
git clone https://github.com/mattanmr/easybacklog.git
cd easybacklog

# 2. Copy environment configuration
cp .env.example .env

# 3. Start all services (database, Redis, web server, background jobs)
docker compose up -d

# 4. Set up the database
docker compose exec web bundle exec rake db:schema:load
docker compose exec web bundle exec rake db:seed

# 5. Open your browser
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

📚 **For more details, see [DOCKER_GUIDE.md](doc/DOCKER_GUIDE.md) and [GETTING_STARTED.md](doc/GETTING_STARTED.md)**

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