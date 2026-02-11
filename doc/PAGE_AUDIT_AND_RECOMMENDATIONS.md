# easyBacklog Main Page Audit & Recommendations

**Date:** January 21, 2026  
**Scope:** Welcome page functionality and external dependencies  
**Goal:** Make the app work locally with minimal external dependencies

---

## 1. Current Main Page Elements

### Working Locally ✅
- **Sign up** → `new_user_registration_path` (Devise route works locally)
- **Log in** → `new_session_path(User)` (Devise route works locally)
- **FAQ** → `faq_path` (Route exists, view exists: `app/views/pages/faq.html.haml`)
- **Support/Contact** → `contact_path` (Route exists, view exists: `app/views/pages/contact.html.haml`)
- Feature cards and carousel (all static content)
- Testimonials, branding, and descriptions

### External Dependencies ⚠️
1. **Blog links** - `http://blog.easybacklog.com/`
   - Location: Header (line 10), Footer (line 214)
   - Status: External site (won't work without internet)
   - Action: **REMOVE or replace with local `/blog` route**

2. **Twitter link** - `http://www.twitter.com/easybacklog`
   - Location: Footer (lines 207-209)
   - Status: External social media (not essential for functionality)
   - Action: **REMOVE from foreground or make optional**

3. **Vimeo video** - `https://player.vimeo.com/video/32169448?...`
   - Location: `.demos .light-box.video-demo` (line 169)
   - Status: External embed (requires internet)
   - Action: **Replace with local video or remove**

4. **Agile Manifesto link** - `http://agilemanifesto.org/`
   - Location: Content section (line 197)
   - Status: External reference (informational)
   - Action: **REMOVE link or add local copy**

5. **Blog link in preferences** - Points to `blog.easybacklog.com`
   - Location: `app/views/_shared/_backlog_preferences.html.haml` (line 46)
   - Status: External
   - Action: **REMOVE or update with local resource**

### Routes Status 📍
```
GET  /                      → welcome#index (working ✅)
GET  /users/sign_up         → registrations#new (Devise, working ✅)
GET  /users/sign_in         → sessions#new (Devise, working ✅)
GET  /contact               → pages#contact (defined in routes but missing controller action)
GET  /faq                   → pages#faq (defined in routes but missing controller action)
```

---

## 2. Issues Found

### A. Missing Controller Actions
**File:** `app/controllers/pages_controller.rb`  
**Issue:** Routes defined for `contact` and `faq`, but no corresponding actions  
**Fix:** Add empty actions (Rails will auto-render matching views)

```ruby
def contact
  # Auto-renders: app/views/pages/contact.html.haml
end

def faq
  # Auto-renders: app/views/pages/faq.html.haml
end
```

### B. External Links
**File:** `app/views/welcome/index.html.haml`

| Line | Element | URL | Impact |
|------|---------|-----|--------|
| 10 | Blog link (header) | http://blog.easybacklog.com/ | Broken link locally |
| 169 | Video demo | https://player.vimeo.com/video/32169448 | Won't load without internet |
| 197 | Agile Manifesto | http://agilemanifesto.org/ | External reference |
| 207-209 | Twitter link | http://www.twitter.com/easybacklog | Social media, not essential |
| 214 | Blog link (footer) | http://blog.easybacklog.com/ | Broken link locally |

### C. Presentation Issues
- Blog links appear twice (header + footer) - repetitive
- Twitter link uses non-semantic markup (`.copy` div with href)
- Video demo requires JavaScript and external dependencies

---

## 3. Recommended Changes

### Priority 1: MUST FIX (For Local Functionality)

**1. Add Missing Controller Actions**
```ruby
# app/controllers/pages_controller.rb - add these methods:

def contact
  # Auto-renders app/views/pages/contact.html.haml
end

def faq
  # Auto-renders app/views/pages/faq.html.haml
end
```

**2. Remove External Blog Links**
Replace in `app/views/welcome/index.html.haml`:
- Line 10: `=link_to 'Blog', 'http://blog.easybacklog.com/'` → Remove entirely
- Line 214: `= link_to 'Blog', 'http://blog.easybacklog.com/'` → Remove entirely

**3. Disable/Remove Video Demo**
Option A (Remove): Delete lines 167-169 (video section)
Option B (Disable): Replace with placeholder text

### Priority 2: SHOULD FIX (For Better UX)

**4. Fix Twitter Section Markup**
Current (lines 207-209):
```haml
%a{:href => 'http://www.twitter.com/easybacklog' }
  .logo
  .copy{:href => 'http://www.twitter.com/easybacklog' } Follow us on twitter
```

Better approach:
- Remove or comment out for local development
- Or make it a proper link:
```haml
= link_to 'Follow us on Twitter', 'http://www.twitter.com/easybacklog', target: '_blank', class: 'twitter-link'
```

**5. Localize Agile Manifesto Link**
Replace line 197:
```ruby
=link_to 'Read the Agile manifesto →', 'http://agilemanifesto.org/'
```
With:
```ruby
=link_to 'Read the Agile manifesto →', '#agile-info'
```
Or remove entirely (it's just a reference)

**6. Fix Blog Link in Preferences**
File: `app/views/_shared/_backlog_preferences.html.haml` (line 46)
Current: Links to `blog.easybacklog.com`
Action: Remove or replace with internal documentation

### Priority 3: NICE TO HAVE (Polish)

**7. Replace Video with Screenshot or Placeholder**
Current: Embedded Vimeo video  
Options:
- Show only screenshot carousel (already works)
- Add local video file
- Show "Video unavailable in local mode" message

**8. Add Local Admin Section**
Consider adding a link for local-only admin/settings for future use

---

## 4. Implementation Plan

### Step 1: Fix Controller (2 min)
Add `contact` and `faq` actions to `PagesController`

### Step 2: Update Welcome View (5 min)
- Remove external blog links (2 occurrences)
- Remove or comment out Twitter section
- Remove or comment out video demo
- Update Agile Manifesto link

### Step 3: Update Preferences Partial (1 min)
- Remove or comment out external blog link

### Step 4: Test (5 min)
- Visit each page locally
- Verify all links work
- Check for console errors

### Step 5: Commit (1 min)
```bash
git add app/controllers/pages_controller.rb app/views/welcome/index.html.haml app/views/_shared/_backlog_preferences.html.haml
git commit -m "chore: Remove external links and fix local development navigation"
git push
```

---

## 5. Summary

**What Works Locally:**
- Sign up/Login (Devise)
- FAQ page
- Contact/Support page
- Feature cards
- Most static content

**What Needs Removal:**
- External blog links (2 occurrences) → REMOVE
- Twitter social link → REMOVE or make optional
- Video demo embed → REMOVE or replace
- External manifesto link → REMOVE

**What Needs Fixing:**
- Missing controller actions for `contact` and `faq` → ADD 2 methods
- Inaccurate links in preferences partial → UPDATE

**Estimated Time:** ~15 minutes to implement all fixes

---

## 6. Respect for Project Creators

All changes are **non-destructive** and **reversible**:
- Only removing external dependencies for local development
- Can be re-enabled for production deployment
- Comments show original URLs for reference
- Core business logic and features remain intact
- User registration, login, and core workflows unchanged

**Note:** Consider adding a `.env` flag like `DEPLOYMENT_MODE` to conditionally show/hide external links between local dev and production.

