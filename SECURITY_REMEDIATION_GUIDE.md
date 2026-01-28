# Security Remediation Guide

## Overview

This document provides detailed remediation steps for all security issues identified during the security review of the EasyBacklog Rails application.

---

## Completed Fixes ✅

### 1. Hardcoded Secret Token - FIXED
**Severity:** CRITICAL  
**CWE:** CWE-798

**What was fixed:**
- Moved secret_token from hardcoded value to environment variable
- File: `config/initializers/secret_token.rb`

**Action required:**
1. Generate a new secret key: `openssl rand -hex 64`
2. Add to your `.env` file: `SECRET_KEY_BASE=your_generated_secret`
3. Never commit the `.env` file to version control

---

### 2. Hardcoded Database Passwords - FIXED
**Severity:** HIGH  
**Files:** `docker-compose.yml`

**What was fixed:**
- Database credentials now use environment variables
- Fallback defaults only for development

**Action required:**
1. Set secure passwords in `.env`:
   ```
   DB_USERNAME=postgres
   DB_PASSWORD=your_secure_password_here
   DB_NAME=easybacklog_production
   ```

---

### 3. Docker Running as Root - FIXED
**Severity:** HIGH  
**File:** `Dockerfile`

**What was fixed:**
- Created non-root user `appuser`
- Container now runs as `appuser` instead of root
- Proper file permissions set

**Benefits:**
- Limits damage from container escape vulnerabilities
- Follows Docker security best practices

---

### 4. Missing SSL Enforcement - FIXED
**Severity:** HIGH  
**File:** `config/environments/production.rb`

**What was fixed:**
- Added `config.force_ssl = true` for production
- All HTTP traffic redirected to HTTPS
- Secure cookies enforced

**Action required:**
- Configure SSL certificates on your web server/load balancer

---

### 5. Missing CSRF Protection - FIXED
**Severity:** HIGH  
**Files:** `app/controllers/api_controller.rb`, `app/controllers/health_controller.rb`

**What was fixed:**
- Added explicit CSRF handling with documentation
- API uses `:null_session` (appropriate for token auth)
- Health endpoint uses `:null_session` (read-only endpoint)

---

### 6. Regex Validation Vulnerabilities - FIXED
**Severity:** MEDIUM  
**Files:** `app/models/beta_signup.rb`, `app/models/theme.rb`

**What was fixed:**
- Changed regex anchors from `^` and `$` to `\A` and `\z`
- Prevents multiline bypass attacks

---

### 7. Mass Assignment Protection - FIXED
**Severity:** HIGH  
**Files:** Multiple model files

**What was fixed:**
- Added `attr_accessible` to all models that were missing it:
  - `SprintStoryStatus`
  - `AccountUser`
  - `Locale`
  - `CompanyUser`
  - `CronLog`
  - `BacklogUser`
  - `ScoringRule`

---

### 8. Security Headers - FIXED
**Severity:** MEDIUM  
**File:** `config/initializers/security_headers.rb` (new)

**What was added:**
- X-Frame-Options: SAMEORIGIN
- X-XSS-Protection: 1; mode=block
- X-Content-Type-Options: nosniff
- Content-Security-Policy (production only)
- Referrer-Policy
- Permissions-Policy

---

## Remaining Issues to Address

### 9. EOL Rails and Ruby Versions ⚠️ 
**Severity:** CRITICAL  
**Status:** REQUIRES PLANNING

**Issue:**
- Rails 3.2.22 - EOL since June 2016
- Ruby 2.6.10 - EOL since March 2022

**Multiple CVEs affecting:**
- actionmailer, actionpack, activerecord, activeresource, activesupport
- Total: 50+ known vulnerabilities

**Recommended path:**
1. **Phase 1** (1-2 months): Rails 3.2 → 4.2
2. **Phase 2** (1-2 months): Rails 4.2 → 5.2
3. **Phase 3** (1-2 months): Rails 5.2 → 6.1
4. **Phase 4** (1-2 months): Ruby 2.6 → 2.7 → 3.x

**Why this is challenging:**
- Breaking changes between major versions
- Gem compatibility issues
- Extensive testing required
- Potential code refactoring needed

**Immediate mitigation:**
- Apply available security patches for Rails 3.2.x
- Monitor for active exploitation
- Implement WAF rules to mitigate known CVEs
- Restrict access to trusted networks if possible

---

### 10. Gem Vulnerabilities ⚠️
**Severity:** HIGH  
**Status:** REQUIRES REVIEW

**Critical gems with known CVEs:**
- `nokogiri` - Multiple XML parsing vulnerabilities
- `devise` - Authentication bypass vulnerabilities
- `rack` - Request handling vulnerabilities
- `json` - Denial of service vulnerabilities

**Action required:**
1. Run `bundle-audit check --update` regularly
2. Update gems where Rails 3.2 compatible versions exist
3. Track gems that require Rails upgrade to fix
4. Consider backporting security patches where feasible

---

### 11. XSS Vulnerabilities (Medium Risk) ⚠️
**Severity:** MEDIUM  
**Status:** REVIEW NEEDED

**Affected files:**
- `app/views/backlogs/edit.html.haml` (lines 123, 125)
- `app/views/backlogs/show.html.haml` (lines 141, 152)
- `app/views/company_users/index.html.haml` (line 38)
- `app/views/backlog_users/index.html.haml` (line 41)
- `app/views/user_tokens/index.html.haml` (line 26)
- `app/helpers/privileges_helper.rb` (line 27)

**Issue:**
- Unescaped model attributes in views
- Use of `raw` helper without sanitization

**Remediation:**
1. Review each occurrence
2. Ensure data is properly escaped
3. Use `sanitize` helper for HTML content
4. Remove `raw` unless absolutely necessary
5. Update to Rails version with better XSS protection

**Example fix:**
```ruby
# Before
= raw some_content

# After - if HTML is needed
= sanitize some_content, tags: %w(p br strong em)

# After - if plain text
= some_content  # auto-escaped in Rails 3.2+
```

---

### 12. Content Tag CVE-2016-6316 ⚠️
**Severity:** MEDIUM  
**Status:** REQUIRES RAILS UPGRADE

**Issue:**
Rails 3.2.22 `content_tag` doesn't escape double quotes in attributes

**Workaround:**
Manually escape attributes when using content_tag:
```ruby
content_tag(:div, content, class: ERB::Util.html_escape(user_input))
```

**Long-term fix:**
Upgrade to Rails 3.2.22.4+ or higher

---

### 13. CSRF Token Forgery CVE-2020-8166 ⚠️
**Severity:** MEDIUM  
**Status:** REQUIRES RAILS UPGRADE

**Issue:**
Rails 3.2.22 vulnerable to CSRF token forgery

**Mitigation:**
- Ensure all forms use CSRF tokens (already done)
- Monitor for suspicious activity
- Consider per-form CSRF tokens if feasible

**Long-term fix:**
Upgrade to Rails 5.2.4.3+ or Rails 6.0.3.1+

---

### 14. Mass Assignment - Potentially Dangerous Attributes ⚠️
**Severity:** MEDIUM  
**Status:** REVIEW RECOMMENDED

**Models with potentially dangerous accessible attributes:**
- `Story`: `:unique_id`
- `Company`, `Account`, `Backlog`: `:locale_id`, `:scoring_rule_id`
- `SprintStory`: `:sprint_id`, `:story_id`, `:sprint_story_status_id`
- `InvitedUser`: `:invitee_user_id`

**Action required:**
1. Review if these attributes should be mass-assignable
2. If not, remove from `attr_accessible`
3. Use strong parameters (Rails 4+) when upgrading
4. Test that functionality still works after changes

---

### 15. Denial of Service Vulnerabilities ⚠️
**Severity:** MEDIUM  
**Status:** REQUIRES RAILS UPGRADE

**CVEs:**
- CVE-2016-0751: MIME type caching DoS
- CVE-2023-22795: ReDoS in Action Dispatch
- CVE-2023-22792: ReDoS in Action Dispatch
- CVE-2022-44566: PostgreSQL adapter DoS

**Mitigation:**
- Implement rate limiting at application or WAF level
- Monitor resource usage
- Set connection timeouts

**Long-term fix:**
Upgrade Rails version

---

### 16. Information Disclosure Vulnerabilities ⚠️
**Severity:** MEDIUM  
**Status:** REQUIRES RAILS UPGRADE

**CVEs:**
- CVE-2016-0752: Information leak in Action View
- CVE-2016-2097: Information leak in Action View
- CVE-2021-22885: Unintended method execution

**Mitigation:**
- Ensure detailed exceptions are disabled in production (already done)
- Review error messages shown to users
- Implement proper access controls

---

### 17. Remote Code Execution Vulnerabilities ⚠️
**Severity:** CRITICAL  
**Status:** REQUIRES IMMEDIATE ATTENTION

**CVEs:**
- CVE-2016-2098: RCE in Action Pack
- CVE-2022-32224: RCE with Serialized Columns

**CRITICAL MITIGATIONS:**
1. **Disable YAML/Marshal deserialization** where possible
2. **Review all uses of `serialize` in models**
3. **Validate data before deserialization**
4. **Implement WAF rules** to block malicious payloads
5. **Restrict network access** to trusted sources

**Example - Secure serialization:**
```ruby
# Instead of:
serialize :data

# Consider:
serialize :data, JSON  # Safer than YAML/Marshal
```

---

## Implementation Priority

### Immediate (Do Now):
1. ✅ Set SECRET_KEY_BASE in environment
2. ✅ Set secure database passwords
3. ⚠️ Review and secure serialized columns (CVE-2022-32224)
4. ⚠️ Implement rate limiting
5. ⚠️ Set up WAF if possible

### Short Term (1-2 weeks):
6. Review and fix XSS vulnerabilities
7. Review mass assignment attributes
8. Update gems where possible
9. Implement comprehensive logging
10. Set up security monitoring

### Medium Term (1-3 months):
11. Plan Rails/Ruby upgrade path
12. Comprehensive security testing
13. Third-party security audit
14. Disaster recovery planning

### Long Term (3-6 months):
15. Execute Rails upgrade
16. Execute Ruby upgrade
17. Modernize authentication
18. Implement zero-trust architecture

---

## Testing Your Fixes

After implementing fixes, verify:

```bash
# 1. Run Brakeman
docker-compose exec web bundle exec brakeman -o brakeman-report.json

# 2. Run bundle-audit
docker-compose exec web bundle exec bundle-audit check --update

# 3. Check security headers
curl -I https://your-domain.com

# 4. Test CSRF protection
# Try submitting forms without CSRF token

# 5. Test mass assignment
# Try to set restricted attributes via API

# 6. Verify SSL enforcement
curl http://your-domain.com
# Should redirect to https://
```

---

## Continuous Security

### Automated Scanning
Add to CI/CD pipeline:
```yaml
# .github/workflows/security.yml
name: Security Scan
on: [push, pull_request]
jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run Brakeman
        run: |
          gem install brakeman
          brakeman -o brakeman-report.json
      - name: Run bundle-audit
        run: |
          gem install bundler-audit
          bundle-audit check --update
```

### Regular Reviews
- Weekly: Run bundle-audit
- Monthly: Run Brakeman
- Quarterly: Third-party penetration test
- Continuously: Monitor security advisories

---

## Additional Resources

- [Rails Security Guide](https://guides.rubyonrails.org/security.html)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Ruby Security Announcements](https://groups.google.com/g/ruby-security-ann)
- [Rails Security Mailing List](https://groups.google.com/g/rubyonrails-security)

---

## Questions or Issues?

For security-sensitive issues, please contact the maintainers privately.
For general questions, open a GitHub issue.
