# Secure Docker Setup Guide

This guide provides instructions for securely setting up and deploying the EasyBacklog application using Docker.

## Prerequisites

- Docker and Docker Compose installed
- Access to the repository
- Basic understanding of Docker and Rails

## Security Considerations

### 1. Environment Variables

**CRITICAL**: Never commit `.env` files to version control. The `.env` file contains sensitive credentials.

Create your `.env` file from the example:

```bash
cp .env.example .env
```

### 2. Generate Secure Secret Keys

Generate a new SECRET_KEY_BASE for your environment:

```bash
# Using openssl
openssl rand -hex 64

# Or using Rails (if you have it installed locally)
rake secret
```

Update your `.env` file with the generated secret:

```
SECRET_KEY_BASE=your_generated_secret_here
```

### 3. Database Credentials

**Development**:
The default credentials in `docker-compose.yml` use environment variables with fallback defaults.

For development, you can use:
```
DB_USERNAME=postgres
DB_PASSWORD=postgres_dev_password
DB_NAME=easybacklog_development
```

**Production**:
NEVER use default passwords in production. Generate strong passwords:

```bash
# Generate a strong password
openssl rand -base64 32
```

### 4. External Service Credentials

Update the following in your `.env` file:

```
SENDGRID_USERNAME=your_sendgrid_username
SENDGRID_PASSWORD=your_sendgrid_password
ABLY_API_KEY=your_ably_api_key
```

## Building and Running

### Development

1. Create and configure your `.env` file as described above

2. Build the containers:
```bash
docker-compose build
```

3. Start the services:
```bash
docker-compose up
```

4. Run database migrations:
```bash
docker-compose exec web bundle exec rake db:create db:migrate
```

5. Access the application at http://localhost:3000

### Production

For production deployment, consider:

1. **Use Docker Secrets** instead of environment variables for sensitive data
2. **Enable SSL/TLS** - The application enforces SSL in production
3. **Use a reverse proxy** (nginx/traefik) for SSL termination
4. **Set up container health checks**
5. **Configure resource limits** in docker-compose.yml
6. **Use read-only file systems** where possible
7. **Scan images** for vulnerabilities before deployment

Example production docker-compose additions:

```yaml
services:
  web:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 512M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
```

## Security Best Practices

### Running as Non-Root User

The Dockerfile has been configured to run as a non-root user (`appuser`) for security.

### SSL/TLS Configuration

In production, the application enforces SSL:
- `config.force_ssl = true` in `config/environments/production.rb`
- All HTTP traffic will be redirected to HTTPS
- Secure cookies will be used

### Security Headers

The application sets the following security headers:
- X-Frame-Options: SAMEORIGIN (prevent clickjacking)
- X-XSS-Protection: 1; mode=block (XSS protection)
- X-Content-Type-Options: nosniff (prevent MIME sniffing)
- Content-Security-Policy (in production)
- Referrer-Policy: strict-origin-when-cross-origin

### CSRF Protection

CSRF protection is enabled for all non-API requests:
- API endpoints use token-based authentication
- Web requests use Rails' built-in CSRF protection

## Monitoring and Logging

### Health Check Endpoint

The application provides a health check endpoint:
```
GET /health/status
```

This endpoint:
- Returns 200 OK if the application is healthy
- Returns 500 if there are issues
- Checks database connectivity
- Does not require authentication

### Viewing Logs

```bash
# View all logs
docker-compose logs

# Follow logs
docker-compose logs -f

# View specific service logs
docker-compose logs web
docker-compose logs sidekiq
```

## Backup and Recovery

### Database Backups

Regular database backups are essential:

```bash
# Backup database
docker-compose exec db pg_dump -U postgres easybacklog_development > backup.sql

# Restore database
docker-compose exec -T db psql -U postgres easybacklog_development < backup.sql
```

### Volume Backups

Docker volumes persist data. Back them up regularly:

```bash
# List volumes
docker volume ls

# Backup a volume
docker run --rm -v easybacklog_postgres_data:/data -v $(pwd):/backup \
  ubuntu tar czf /backup/postgres_data_backup.tar.gz /data
```

## Troubleshooting

### Permission Issues

If you encounter permission issues with volumes:

```bash
# Fix ownership (run as root user temporarily)
docker-compose exec -u root web chown -R appuser:appuser /app
```

### Database Connection Issues

Check that the database is healthy:

```bash
docker-compose ps
docker-compose logs db
```

### Secret Token Issues

If you see errors about SECRET_KEY_BASE:

1. Verify your `.env` file exists and contains SECRET_KEY_BASE
2. Restart the containers: `docker-compose restart`
3. Check logs: `docker-compose logs web`

## Maintenance

### Updating Dependencies

```bash
# Update gems
docker-compose exec web bundle update

# Rebuild containers
docker-compose build --no-cache
```

### Running Security Scans

```bash
# Run Brakeman security scanner
docker-compose exec web bundle exec brakeman

# Run bundle-audit for gem vulnerabilities  
docker-compose exec web bundle exec bundle-audit check --update
```

## Production Checklist

Before deploying to production, ensure:

- [ ] All environment variables are set with strong credentials
- [ ] SECRET_KEY_BASE is unique and never committed to git
- [ ] Database passwords are strong and rotated regularly
- [ ] SSL/TLS certificates are properly configured
- [ ] Security headers are enabled
- [ ] Health checks are configured
- [ ] Logging and monitoring are set up
- [ ] Backup strategy is in place
- [ ] Container resource limits are defined
- [ ] Images are scanned for vulnerabilities
- [ ] Non-root user is configured (already done)
- [ ] Sensitive ports are not exposed publicly
- [ ] Rate limiting is configured (if applicable)

## Security Updates

To stay secure:

1. **Monitor security advisories** for Rails, Ruby, and gems
2. **Update regularly** - especially security patches
3. **Run security scans** before each deployment
4. **Review logs** for suspicious activity
5. **Keep Docker images updated** to latest patch versions

## Known Security Considerations

### EOL Software
- **Rails 3.2.22**: End of life since 2016-06-30
- **Ruby 2.6.10**: End of life since 2022-03-31

**Recommendation**: Plan an upgrade to supported versions:
- Target: Rails 6.1+ and Ruby 3.x
- This is a significant undertaking requiring careful testing

### Gem Vulnerabilities
Multiple gems have known vulnerabilities. Run `bundle-audit` regularly to identify and update vulnerable dependencies.

## Support and Issues

For security issues, please contact the repository maintainers privately.

For general issues, please open a GitHub issue.
