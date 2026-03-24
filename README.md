# easyBacklog

An intuitive backlog management tool for Agile practitioners. Originally created by [Matthew O'Riordan](https://mattheworiordan.com) and available at easybacklog.com until September 2022. Now open-sourced under the [MIT license](./LICENSE).

See [CHANGELOG.md](CHANGELOG.md) for details on the Docker containerization and other changes made in this fork.

## Tech Stack

- Ruby on Rails 3.2 / Ruby 2.6.10
- PostgreSQL 11
- Redis 5
- Sidekiq (background jobs)
- jQuery + Backbone.js (frontend)
- Devise (authentication)
- HAML + EJS (templates)

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Git](https://git-scm.com/)

## Setup

```bash
git clone https://github.com/mattanmr/easybacklog.git
cd easybacklog
make setup
```

This builds the Docker images, starts all services, and initializes the database. First run takes ~3-5 minutes.

To also load demo data (a sample user, backlog, themes, and stories):

```bash
make setup-with-sample
```

Demo credentials: `demo@example.com` / `password123`

Once running, open http://localhost:3000.

### What's Running

| Service    | Description             | Port |
|------------|-------------------------|------|
| Web        | Rails application       | 3000 |
| PostgreSQL | Database                | 5432 |
| Redis      | Cache and job queue     | 6379 |
| Sidekiq    | Background job worker   | —    |

## Common Commands

Run `make help` for the full list. Key commands:

| Command               | Description                        |
|-----------------------|------------------------------------|
| `make start`          | Start all services                 |
| `make stop`           | Stop all services (keeps data)     |
| `make restart`        | Restart all services               |
| `make logs`           | Follow logs from all services      |
| `make console`        | Open Rails console                 |
| `make bash`           | Shell into the web container       |
| `make db-console`     | Open PostgreSQL console            |
| `make test`           | Run RSpec tests                    |
| `make test-cucumber`  | Run Cucumber integration tests     |
| `make db-seed-sample` | Load demo data                     |
| `make status`         | Show running containers            |
| `make reset`          | Tear down everything (deletes data)|

## Configuration

Copy `.env.example` to `.env` to customize settings. `make setup` does this automatically if `.env` doesn't exist.

All external services (SendGrid, Ably, New Relic) are disabled by default. The application works fully offline. See `.env.example` for details on enabling them.

## License

[MIT](./LICENSE)