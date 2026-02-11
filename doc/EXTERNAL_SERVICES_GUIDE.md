# External Services Configuration Guide

## Overview

By default, **all external services are disabled** for local development to ensure complete data privacy and isolation. This means no data leaves your localhost during development.

## Disabled Services

The following external services are disabled by default:

1. **SendGrid SMTP** - Email delivery service
2. **Google Analytics** - Usage tracking and analytics
3. **UserEcho** - Feedback widget and support forum
4. **Ably** - Real-time messaging API
5. **Exceptional** - Error tracking and reporting
6. **New Relic** - Performance monitoring

## How It Works

A new initializer (`config/initializers/external_services.rb`) provides a central control mechanism through the `ExternalServices` module. All external service integrations check this module before making external connections.

## Re-enabling Services

### Enable All Services at Once

Set the environment variable:
```bash
export ENABLE_EXTERNAL_SERVICES=true
```

Or in your `.env` file:
```
ENABLE_EXTERNAL_SERVICES=true
```

### Enable Individual Services

You can enable services individually without enabling all of them:

```bash
# Email only
export ENABLE_EMAIL=true

# Analytics only
export ENABLE_ANALYTICS=true

# Feedback widget only
export ENABLE_FEEDBACK=true

# Real-time features only
export ENABLE_REALTIME=true

# Error tracking only
export ENABLE_ERROR_TRACKING=true

# Performance monitoring only
export ENABLE_PERFORMANCE_MONITORING=true
```

### Required API Keys

Some services require API keys even when enabled:

| Service | Environment Variable | Required |
|---------|---------------------|----------|
| SendGrid | `SENDGRID_USERNAME`, `SENDGRID_PASSWORD` | Yes |
| Ably | `ABLY_API_KEY` | Yes |
| New Relic | `NEW_RELIC_LICENSE_KEY` | Yes (if installed) |
| Exceptional | API key in config | Yes (if used) |
| Google Analytics | Hardcoded in view | No |
| UserEcho | Hardcoded in view | No |

## Files Modified

The following files were updated to support conditional external services:

### Configuration Files
- `config/initializers/external_services.rb` - **NEW** - Central control module
- `config/initializers/mail.rb` - Email delivery control
- `config/active_record_initializers/newrelic_and_unicorn.rb` - New Relic control

### Controller Files
- `app/controllers/pages_controller.rb` - Ably real-time API control
- `app/controllers/application_controller.rb` - Exceptional error tracking control

### View Files
- `app/views/layouts/_head.html.haml` - Google Analytics control
- `app/views/layouts/_user_echo.html.haml` - UserEcho widget control
- `app/views/pages/faq.html.haml` - UserEcho link control
- `app/views/pages/contact.html.haml` - UserEcho link control

## Development Mode

When running in development mode, you'll see a startup message showing the status of all services:

```
================================================================================
EXTERNAL SERVICES STATUS
================================================================================
Email Delivery:          DISABLED
Analytics:               DISABLED
Feedback Widget:         DISABLED
Real-time API:           DISABLED
Error Tracking:          DISABLED
Performance Monitoring:  DISABLED
================================================================================
To enable all services: Set ENABLE_EXTERNAL_SERVICES=true in your environment
To enable individual services: Set ENABLE_<SERVICE>=true
================================================================================
```

## Production Deployment

For production deployment, you can:

1. **Enable all services**: Set `ENABLE_EXTERNAL_SERVICES=true`
2. **Enable specific services**: Set individual flags
3. **Provide API keys**: Ensure all required environment variables are set

## Testing

In test mode, all external services remain disabled regardless of environment variable settings to ensure test isolation.

## Reverting Changes

All changes are non-destructive and reversible:

1. The original code remains intact, just wrapped in conditionals
2. No functionality has been removed, only conditionally disabled
3. All original URLs and configurations are preserved
4. Simply set the environment variables to re-enable services

## Security Note

**Local development is now completely isolated** - no data leaves localhost unless you explicitly enable external services. This ensures:

- No tracking data sent to Google Analytics
- No error reports sent to Exceptional
- No performance metrics sent to New Relic
- No emails sent via SendGrid
- No real-time connections to Ably
- No feedback sent to UserEcho

This makes the application safe for local development with sensitive data.
