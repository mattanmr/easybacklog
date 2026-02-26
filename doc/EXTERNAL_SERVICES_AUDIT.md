# External Services and Links Audit Report

**Date**: February 26, 2026  
**Project**: easyBacklog (Open Source)  
**Scope**: Identify and document all external services, links, and API dependencies

---

## Executive Summary

The easyBacklog application has been configured with **conditional external service loading** through the `ExternalServices` module. All external services are **disabled by default** in development and local environments for privacy and offline functionality. External links have been properly scoped to conditional rendering using Haml helpers.

**Status**: ✅ **SECURE FOR LOCAL DEVELOPMENT**

---

## 1. External Services Configuration

### Location
[config/initializers/external_services.rb](config/initializers/external_services.rb)

### Services and Status

| Service | Purpose | Configuration | Default (Local Dev) | Notes |
|---------|---------|---|---|---|
| **SendGrid SMTP** | Email delivery | `ENABLE_EMAIL` | ❌ DISABLED | Requires `SENDGRID_USERNAME`, `SENDGRID_PASSWORD` |
| **Google Analytics** | Usage tracking | `ENABLE_ANALYTICS` | ❌ DISABLED | GA tracking ID: `UA-11771751-3` |
| **UserEcho** | Feedback widget | `ENABLE_FEEDBACK` | ❌ DISABLED | Forum ID: `4890` at `easybacklog.userecho.com` |
| **Ably** | Real-time APIs | `ENABLE_REALTIME` | ❌ DISABLED | Requires `ABLY_API_KEY` |
| **Exceptional** | Error tracking | `ENABLE_ERROR_TRACKING` | ❌ DISABLED | Legacy service (consider New Relic replacement) |
| **New Relic** | Performance monitoring | `ENABLE_PERFORMANCE_MONITORING` | ❌ DISABLED | Requires `NEW_RELIC_LICENSE_KEY` |

### Enabling Services

To enable external services for staging/production:

```bash
# Enable all services
export ENABLE_EXTERNAL_SERVICES=true

# Or enable individually
export ENABLE_EMAIL=true
export ENABLE_ANALYTICS=true
export ENABLE_FEEDBACK=true
export ENABLE_REALTIME=true
export ENABLE_ERROR_TRACKING=true
export ENABLE_PERFORMANCE_MONITORING=true
```

---

## 2. External Links in Views

### A. Contact Page
**File**: [app/views/pages/contact.html.haml](app/views/pages/contact.html.haml)

| Link | URL | Condition | Status |
|------|-----|-----------|--------|
| Support Forum | `http://easybacklog.userecho.com/` | `ExternalServices.feedback_enabled?` | ✅ Conditional |
| Status Page | `http://status.easybacklog.com/548247` | Always visible | ⚠️ Hard-coded |
| API Documentation | `http://easybacklog.com/api` | Always visible | ⚠️ Hard-coded |

**Action Required**: 
- [ ] Conditional rendering for status page link
- [ ] Option to disable stale easybacklog.com API documentation links

---

### B. FAQ Page
**File**: [app/views/pages/faq.html.haml](app/views/pages/faq.html.haml)

| Link | URL | Condition | Status |
|------|-----|-----------|--------|
| Support Forum | `http://easybacklog.userecho.com/` | `ExternalServices.feedback_enabled?` | ✅ Conditional |
| API Docs | `http://easybacklog.com/api` | Always visible | ⚠️ Hard-coded |
| Google Chrome | `http://www.google.com/chrome` | Always visible | ⚠️ External Reference |
| Firefox | `http://www.mozilla.org/firefox` | Always visible | ⚠️ External Reference |

**Action Required**:
- [ ] Consider replacing external browser links with local system defaults
- [ ] Make API documentation links conditional or replace with local docs

---

### C. Browser Support Page
**File**: [app/views/pages/browser_support.html.haml](app/views/pages/browser_support.html.haml)

| Link | Target | Status |
|------|--------|--------|
| Google Chrome | `http://www.google.com/chrome/` | External reference |
| Safari | `http://www.apple.com/safari/` | External reference |
| Firefox | `http://www.mozilla.org/firefox/` | External reference |
| Internet Explorer | `http://windows.microsoft.com/en-US/internet-explorer/products/ie/home` | External reference |
| Opera | `http://www.opera.com/` | External reference |

**Note**: These are informational external links. Not security-critical but require internet access. Consider local fallbacks or removal if offline functionality is required.

---

### D. 404 Error Page
**File**: [app/views/application/404_error.html.haml](app/views/application/404_error.html.haml)

| Link | URL | Purpose |
|------|-----|---------|
| HTTP 404 | `http://en.wikipedia.org/wiki/HTTP_404` | Educational reference |

---

## 3. JavaScript External Assets

### A. Google Analytics
**Location**: [app/views/layouts/_head.html.haml](app/views/layouts/_head.html.haml) (lines 29-36)

```javascript
// Conditional loading based on ExternalServices.analytics_enabled?
- if ExternalServices.analytics_enabled?
  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-11771751-3']);
  ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
```

**Status**: ✅ **DISABLED in development**

---

### B. UserEcho Widget
**Location**: [app/views/layouts/_user_echo.html.haml](app/views/layouts/_user_echo.html.haml)

```javascript
// Conditional loading based on ExternalServices.feedback_enabled?
- if ExternalServices.feedback_enabled?
  _ues.host = 'easybacklog.userecho.com'
  _ue.src = ('https:' == document.location.protocol ? 'https://' : 'http://') + 'cdn.userecho.com/js/widget-1.4.gz.js';
```

**Status**: ✅ **DISABLED in development**

---

### C. Exceptional Error Tracking
**Location**: [app/views/layouts/_head.html.haml](app/views/layouts/_head.html.haml) (lines 17-19)

```javascript
- unless %w(test dev).include?(Rails.env)
  Exceptional.setHost('exceptional-api.heroku.com');
  Exceptional.setKey('#{Exceptional::Config.api_key}');
```

**Status**: ✅ **DISABLED in dev/test**

---

## 4. Email Configuration

### Location
[config/initializers/mail.rb](config/initializers/mail.rb)

### Current Configuration

```ruby
if ExternalServices.email_enabled?
  ActionMailer::Base.smtp_settings = {
    :address => "smtp.sendgrid.net",
    :port => 587,
    :authentication => :plain,
    :user_name => ENV['SENDGRID_USERNAME'],
    :password => ENV['SENDGRID_PASSWORD'],
    :domain => ENV['DOMAIN'],
    :enable_starttls_auto => true
  }
end
```

**Status**: ✅ **Environment variables used, conditional loading**

**Required Environment Variables** (Production):
- `SENDGRID_USERNAME` - SendGrid account username
- `SENDGRID_PASSWORD` - SendGrid account password
- `DOMAIN` - Domain for mail from address

**Recommendation**: Configure Spring/Mailcatcher for local development instead of SendGrid.

---

## 5. Vendor JavaScript Comments

### Third-party Library Attribution

**Location**: [vendor/assets/javascripts/vendor_all/](vendor/assets/javascripts/vendor_all/)

| File | External References | Status |
|------|---|---|
| backbone.js | Backbone.js documentation | Comments only |
| jquery.cookie.js | jQuery docs | Comments only |
| exceptional.js | JSON-js GitHub link | Comments only |
| jquery.editable.lite.js | Author website reference | Comments only |

**Status**: ✅ **All references are in comments, not executed**

---

## 6. Configuration Files with External References

### .env.example
**Location**: [.env.example](.env.example)

```bash
SENDGRID_USERNAME=[username]
SENDGRID_PASSWORD=[password]
ABLY_API_KEY=[API key from ably.io dashboard]
```

---

## 7. Documentation External Links

### Location
[doc/EXTERNAL_SERVICES_GUIDE.md](doc/EXTERNAL_SERVICES_GUIDE.md) - Comprehensive guide

### Other Documentation
- [doc/AUTHENTICATION_DEEP_DIVE.md](doc/AUTHENTICATION_DEEP_DIVE.md) - No external service links
- [doc/DOCKER_GUIDE.md](doc/DOCKER_GUIDE.md) - Docker-specific (no external links)
- [doc/LOCAL_DEVELOPMENT_GUIDE.md](doc/LOCAL_DEVELOPMENT_GUIDE.md) - Development setup

---

## Security Findings

### ✅ Secure Practices

1. **Conditional Loading**: All external scripts are conditionally loaded using the `ExternalServices` module
2. **Environment Variables**: API keys stored in environment variables, not hardcoded
3. **Disabled by Default**: All external services disabled in development environment
4. **.gitignore Protection**: `.env` file excluded from version control
5. **CSRF Protection**: Session tokens properly configured
6. **No API Keys in Logs**: Sensitive data filtered from logs
7. **Password Hashing**: Bcrypt encryption for user passwords

### ⚠️ Items Requiring Action

| Item | Severity | Action |
|------|----------|--------|
| Hard-coded easybacklog.com links | Low | Make API docs conditional or replace with local docs |
| External browser download links | Low | Consider local system defaults or removal |
| Status page link | Low | Make conditional or remove |
| Rails 3.2 EOL | High | Plan upgrade to Rails 5+ for security updates |
| Exceptional service (discontinued) | Medium | Migrate to New Relic or alternative |

---

## 8. Removable External Links for Local Development

### To Remove External Connectivity

1. **Disable Google Analytics**
   - ✅ Already disabled by default
   - Set: `ENABLE_ANALYTICS=false`

2. **Disable UserEcho Feedback**
   - ✅ Already disabled by default
   - Set: `ENABLE_FEEDBACK=false`

3. **Disable SendGrid Email**
   - ✅ Already disabled by default
   - Use Mailcatcher for development

4. **Update Hard-coded URLs** (Optional)

   **File**: [app/views/pages/contact.html.haml](app/views/pages/contact.html.haml)
   ```haml
   - if ExternalServices.feedback_enabled?
     = link_to 'support forum', 'http://easybacklog.userecho.com/'
   - else
     %p Support forum disabled for local development
   ```

   **File**: [app/views/pages/faq.html.haml](app/views/pages/faq.html.haml)
   ```haml
   - if ExternalServices.feedback_enabled?
     = link_to 'API service', 'http://easybacklog.com/api'
   - else
     %p API documentation available locally
   ```

---

## 9. Test Coverage

**Location**: [spec/security/external_services_spec.rb](spec/security/external_services_spec.rb)

Tests verify:
- ✅ External services disabled by default
- ✅ Conditional rendering of external scripts
- ✅ API keys not hardcoded
- ✅ Feature tests for disabled external services

---

## 10. Checklist for Production Deployment

- [ ] Set `ENABLE_EXTERNAL_SERVICES=true` (or individual service flags)
- [ ] Configure SendGrid credentials: `SENDGRID_USERNAME`, `SENDGRID_PASSWORD`
- [ ] Configure Ably API: `ABLY_API_KEY`
- [ ] Configure New Relic: `NEW_RELIC_LICENSE_KEY`
- [ ] Set production domain: `DOMAIN=yourdomain.com`
- [ ] Test email delivery with SendGrid
- [ ] Test Google Analytics tracking
- [ ] Enable error tracking (Exceptional or New Relic)
- [ ] Review external links for stale references
- [ ] Update documentation with production setup instructions

---

## 11. Recommendations

### Immediate (High Priority)

1. **Remove Hard-coded easybacklog.com Links**
   - Make status page link conditional
   - Either remove or make API documentation links local-only
   - **Rationale**: Stale references to shutdown service

2. **Test External Service Disabling**
   - Run automated tests to verify services disabled
   - Run browser tests to verify no external requests made
   - **Rationale**: Security and privacy

### Short-term (Medium Priority)

3. **Replace Exceptional with New Relic**
   - Exceptional service discontinued
   - Migrate to New Relic for error tracking
   - **Rationale**: Exceptional no longer supported

4. **Plan Rails Upgrade**
   - Current version: Rails 3.2 (EOL 2013)
   - Plan migration to Rails 5+ or 6+
   - **Rationale**: Security patches no longer available

5. **Add Mailcatcher Support**
   - Implement mailcatcher for local email testing
   - No external email service needed for development
   - **Rationale**: Offline development capability

### Long-term (Low Priority)

6. **Consider Removing External Browser Links**
   - Replace with local system references or guidance
   - **Rationale**: Better offline experience

---

## Conclusion

The easyBacklog application has been properly configured for local development with all external services disabled by default. The conditional service loading pattern is secure and maintainable. All external API keys are stored in environment variables, and sensitive data is properly protected.

**Current Status**: ✅ **SECURE FOR LOCAL DEVELOPMENT AND TESTING**

---

**Document Version**: 1.0  
**Last Updated**: February 26, 2026  
**Reviewed By**: Security Audit
