# easyBacklog Runtime Compose (v1.0.0)

This release includes a single-file Docker Compose setup for pull-and-run usage.

## Download one file

Download `easybacklog-compose.yml` from this release.

## Start on another machine

```bash
docker compose -f easybacklog-compose.yml pull
docker compose -f easybacklog-compose.yml up -d
```

Open the app at http://localhost:3000

## One-time database initialization (first run only)

```bash
docker compose -f easybacklog-compose.yml exec web bundle exec rake db:schema:load
docker compose -f easybacklog-compose.yml exec web bundle exec rake db:seed
docker compose -f easybacklog-compose.yml exec web bundle exec rake db:seed:sample
```

Demo credentials:
- Email: demo@example.com
- Password: password123

## Persistence

Database data is persisted in Docker volume `postgres_data` and survives restarts.
Data is deleted only if you run:

```bash
docker compose -f easybacklog-compose.yml down -v
```

## Stop / logs

```bash
docker compose -f easybacklog-compose.yml logs -f web
docker compose -f easybacklog-compose.yml down
```
