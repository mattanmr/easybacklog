# easyBacklog Runtime Compose (v1.0.0)

This release includes a single-file Docker Compose setup for pull-and-run usage.

## Download one file

Download `docker-compose.yml` from this release.

## Start on another machine

```bash
docker compose pull
docker compose up -d
```

Open the app at http://localhost:3000

## One-time database initialization (first run only)

```bash
docker compose exec web bundle exec rake db:schema:load
docker compose exec web bundle exec rake db:seed
docker compose exec web bundle exec rake db:seed:sample
```

Demo credentials:
- Email: demo@example.com
- Password: password123

## Persistence

Database data is persisted in Docker volume `postgres_data` and survives restarts.
Data is deleted only if you run:

```bash
docker compose down -v
```

## Stop / logs

```bash
docker compose logs -f web
docker compose down
```
