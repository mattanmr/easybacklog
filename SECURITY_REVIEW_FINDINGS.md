# Security Review Findings

## Executive Summary
This document outlines the security vulnerabilities discovered during the comprehensive security review of the EasyBacklog Rails application with Docker migration.

**Total Findings:** 35 from Brakeman + Multiple gem vulnerabilities from bundler-audit
**Critical Severity:** Multiple
**High Severity:** Multiple
**Medium Severity:** Multiple
**Low Severity:** Multiple

---

## Critical/High Priority Issues

### 1. **Hardcoded Secret Token** ⚠️ CRITICAL
- **File:** `config/initializers/secret_token.rb`
- **Issue:** Secret token is hardcoded in version control
- **Risk:** Attackers can forge session cookies and gain unauthorized access
- **CWE:** CWE-798 (Use of Hard-coded Credentials)
- **Remediation:** Move secret to environment variable

### 2. **Hardcoded Database Passwords in Docker** ⚠️ HIGH
- **File:** `docker-compose.yml`
- **Issue:** Database password hardcoded as "password"
- **Risk:** Easy credential guess, exposed in version control
- **Remediation:** Use secrets management or environment variables

### 3. **Unmaintained Dependencies** ⚠️ CRITICAL
- **Rails Version:** 3.2.22 (EOL since 2016-06-30)
- **Ruby Version:** 2.6.10 (EOL since 2022-03-31)
- **Risk:** No security patches, multiple known CVEs
- **CVEs:** Multiple critical vulnerabilities in Rails components
  - CVE-2022-32224 (Critical RCE with Serialized Columns)
  - CVE-2020-8165 (Critical unintended unmarshalling)
  - CVE-2016-2098 (High RCE vulnerability)
  - CVE-2021-22885 (High information disclosure)
- **Remediation:** Plan Rails and Ruby upgrade

### 4. **Mass Assignment Vulnerabilities** ⚠️ HIGH
- **Models Without Protection:**
  - `SprintStoryStatus`
  - `AccountUser`
  - `Locale`
  - `CompanyUser`
  - `CronLog`
  - `BacklogUser`
  - `ScoringRule`
- **Potentially Dangerous Attributes:**
  - `Story`: `:unique_id`
  - `Company`: `:locale_id`
  - `Account`: `:scoring_rule_id`, `:locale_id`
  - `SprintStory`: `:sprint_id`, `:sprint_story_status_id`, `:story_id`
  - `Backlog`: `:scoring_rule_id`, `:locale_id`
  - `InvitedUser`: `:invitee_user_id`
- **Risk:** Attackers can modify restricted attributes
- **Remediation:** Add `attr_accessible` to all models

### 5. **Missing CSRF Protection** ⚠️ HIGH
- **Controllers:**
  - `ApiController`
  - `HealthController`
- **Risk:** CSRF attacks on API endpoints
- **Remediation:** Add `protect_from_forgery` or explicitly document why skipped

### 6. **Docker Security Issues** ⚠️ HIGH
- **Issue:** Running as root user in container
- **File:** `Dockerfile`
- **Risk:** Container escape could compromise host
- **Remediation:** Add non-root user

### 7. **Missing SSL in Production** ⚠️ HIGH
- **File:** `config/environments/production.rb`
- **Issue:** `config.force_ssl` not enabled
- **Risk:** Man-in-the-middle attacks, credential theft
- **Remediation:** Enable SSL enforcement

---

## Medium Priority Issues

### 8. **Cross-Site Scripting (XSS) Vulnerabilities**
- **CVE-2016-6316:** Rails content_tag doesn't escape double quotes
- **Multiple Views:** Unescaped model attributes
  - `app/views/backlogs/edit.html.haml` (line 125, 123)
  - `app/views/backlogs/show.html.haml` (line 152, 141)
  - `app/views/company_users/index.html.haml` (line 38)
  - `app/views/backlog_users/index.html.haml` (line 41)
  - `app/views/user_tokens/index.html.haml` (line 26)
  - `app/helpers/privileges_helper.rb` (line 27)
- **Risk:** XSS attacks, session hijacking
- **Remediation:** Upgrade Rails, properly escape output

### 9. **Regex Validation Vulnerabilities**
- **Files:**
  - `app/models/beta_signup.rb` (email validation)
  - `app/models/theme.rb` (code validation)
- **Issue:** Using `^` and `$` instead of `\A` and `\z`
- **Risk:** Bypass validation, injection attacks
- **Remediation:** Update regex anchors

### 10. **Gem Vulnerabilities**
From bundler-audit:
- **actionmailer 3.2.22:** Multiple CVEs including ReDoS
- **actionpack 3.2.22:** 12+ CVEs including XSS, RCE, DoS
- **activerecord 3.2.22:** 5+ CVEs including RCE, DoS
- **activeresource 3.2.22:** Encoding vulnerability
- **activesupport 3.2.22:** XSS, DoS vulnerabilities
- **addressable, nokogiri, devise, rack, json:** Various CVEs

---

## Low Priority / Informational

### 11. **Missing Security Headers**
- Content Security Policy not configured
- X-Frame-Options not set
- X-XSS-Protection not set

### 12. **Session Security**
- Cookie-based sessions (acceptable for this app size)
- Session secret hardcoded (see Critical #1)

### 13. **API Authentication**
- Token authentication implemented
- No rate limiting detected
- SSL enforcement in API (good)

---

## Docker-Specific Findings

### 14. **Base Image Security**
- Using `ruby:2.6.10-bullseye` (EOL Ruby version)
- Debian bullseye base (consider updating to bookworm)

### 15. **Dockerfile Best Practices**
- ✅ Multi-stage could be improved for production
- ❌ Running as root user
- ✅ Cleaning apt cache
- ✅ Using specific version tags
- ❌ No health check in Dockerfile
- ✅ Using .dockerignore

### 16. **Docker Compose Security**
- ❌ Hardcoded passwords in environment variables
- ✅ Using named volumes (good)
- ❌ No resource limits defined
- ✅ Health checks configured
- ❌ Mounting entire app directory (development mode)

### 17. **Secrets Management**
- ✅ `.env` in .gitignore
- ✅ `.env.example` provided
- ❌ Actual secrets should use Docker secrets or external vault
- ❌ Sendgrid credentials in .env.example (should be documented separately)

---

## Configuration Security

### 18. **Database Configuration**
- Using environment variables (good)
- Default password fallback "password" (bad for production)

### 19. **Production Environment**
- Assets compiled with MD5 fingerprinting ✅
- Using CloudFront CDN ✅
- `serve_static_assets = false` ✅
- Missing `config.force_ssl` ❌

### 20. **Environment Variables**
- SENDGRID credentials via ENV ✅
- ABLY_API_KEY via ENV ✅
- Database via ENV ✅
- Secret token NOT via ENV ❌

---

## Testing & CI/CD

### 21. **Security Testing**
- No automated security scanning in CI/CD detected
- Need to add Brakeman to CI pipeline
- Need to add bundler-audit to CI pipeline

---

## Recommendations Priority Matrix

### Immediate (Fix Now):
1. **Move secret_token to ENV variable**
2. **Add non-root user to Dockerfile**
3. **Update docker-compose.yml passwords**
4. **Add `protect_from_forgery` to ApiController**
5. **Enable `force_ssl` in production**

### Short Term (1-2 weeks):
6. Add `attr_accessible` to all models
7. Fix regex validations
8. Add security headers middleware
9. Update .gitignore if needed
10. Add security scanning to CI/CD

### Medium Term (1-3 months):
11. Plan Rails upgrade path (3.2 → 4.2 → 5.2 → 6.1)
12. Plan Ruby upgrade (2.6 → 2.7 → 3.x)
13. Review and update all gems
14. Implement rate limiting for API
15. Add WAF or similar protection

### Long Term (3-6 months):
16. Complete Rails/Ruby migration
17. Comprehensive penetration testing
18. Security audit by third party
19. Implement secrets management (Vault, AWS Secrets Manager)
20. Container security scanning in CI/CD

---

## Tools Used
- **Brakeman 5.4.1:** Static analysis for Rails
- **bundler-audit 0.9.3:** Gem vulnerability scanning
- **Manual code review:** Configuration and Docker files

---

## Next Steps
1. Fix critical and high priority issues
2. Create security hardening PR
3. Document remediation steps
4. Plan upgrade strategy for EOL dependencies
5. Set up automated security scanning
