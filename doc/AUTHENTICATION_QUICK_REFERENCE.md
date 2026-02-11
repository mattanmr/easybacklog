# Sign-Up Mechanism - Quick Reference Guide

## 🔐 Authentication Stack

```
FRAMEWORK: Devise 2.1.4
ENCRYPTION: Bcrypt (passwords)
SESSION: Cookie-based + database
ASYNC: Sidekiq (background emails)
```

---

## 📊 Database Tables Involved

### Three Core Tables:

```
┌─────────────────────┐
│      USERS          │
├─────────────────────┤
│ id                  │
│ name                │
│ email (unique)      │
│ encrypted_password  │  ← Bcrypt encrypted
│ password_salt       │
│ sign_in_count       │
│ current_sign_in_ip  │
│ last_sign_in_at     │
│ remember_created_at │ ← "Remember me" token
│ confirmation_token  │ ← Email verification
└─────────────────────┘
        ↑
        │ (has_many)
        │
┌──────────────────────┐
│ ACCOUNT_USERS        │ ← JOIN TABLE
├──────────────────────┤
│ id                   │
│ user_id (FK)         │
│ account_id (FK)      │
│ admin (boolean)      │
│ privilege (role)     │
└──────────────────────┘
        ↑
        │ (has_many)
        │
┌─────────────────────┐
│    ACCOUNTS         │
├─────────────────────┤
│ id                  │
│ name (unique)       │
│ locale_id (FK)      │
│ default_velocity    │
│ default_rate        │
│ scoring_rule_id     │
└─────────────────────┘
```

---

## 🔄 Sign-Up Flow

### 1️⃣ GET /users/sign_up
```
Show registration form
├─ User fields: name, email, password
├─ Account fields: account name, language
└─ Submit button
```

### 2️⃣ POST /users (Form Submission)
```
Validate User
├─ Name: present?
├─ Email: valid format?
├─ Email: unique?
└─ Password: min 6 chars?

Validate Account
├─ Name: present?
├─ Name: unique?
└─ Locale: selected?
```

### 3️⃣ Encrypt Password
```
Input: "MyPassword123"
     ↓ (Bcrypt algorithm)
Stored: "$2a$10$N9qo8uLOickgx2Z..."
```

### 4️⃣ Create Records
```
INSERT into users
├─ name
├─ email
├─ encrypted_password
└─ sign_in_count: 0

INSERT into accounts
├─ name
├─ locale_id
└─ defaults_set: false

INSERT into account_users
├─ user_id
├─ account_id
├─ admin: true
└─ privilege: "full"
```

### 5️⃣ Setup Account
```
Create example backlog
└─ User granted read/write access
```

### 6️⃣ Create Session
```
Set session[:user_id] = new_user.id
Set browser cookie: _session=...
```

### 7️⃣ Response
```
200 OK
Set-Cookie: _session=abc123xyz
Redirect: /dashboard
Flash: "Account created successfully"
Background job: Send admin notification
```

---

## 🔑 Key Concepts

### Password Encryption (Bcrypt)

| Property | Details |
|----------|---------|
| Algorithm | Bcrypt (one-way hash) |
| Salted | Yes (random salt per password) |
| Slow | By design (resists brute force) |
| Reversible | No (can't decrypt) |
| Validation | Compare hashes during login |

**Example:**
```
User enters: "MyPassword123"
Stored: "$2a$10$..." (encrypted)
Login verification: Compare hashes → Match? → ✅ Login
```

### Session Management

| Aspect | Details |
|--------|---------|
| Storage | Browser cookie + server memory |
| Expiration | ~24 hours (configurable) |
| Remember Me | 2 weeks (persistent token) |
| HTTPS | Cookie encrypted in transit |
| HttpOnly | JavaScript can't access cookie |

**Session Lifecycle:**
```
User signs up → Session created → Stored in cookie
     ↓
Each request → Session checked → User_ID verified
     ↓
Request completed → Session remains (until expire/logout)
     ↓
User logs out → Session destroyed → Cookie deleted
```

### Multi-Account Architecture

```
One user can belong to MULTIPLE accounts:

User: John Doe
├─ Account 1: "Startup Inc" (admin)
├─ Account 2: "ACME Corp" (member)
└─ Account 3: "Freelance" (member)

Each account has:
├─ Different backlogs
├─ Different team members
├─ Different permissions
└─ Different settings
```

---

## 🛡️ Security Layers

```
CLIENT-SIDE VALIDATION
├─ Email format check
├─ Password strength
├─ Form field validation
└─ Real-time feedback
    ↓ (Fast UX, not secure)

SERVER-SIDE VALIDATION ← ENFORCED
├─ Email format check
├─ Email uniqueness query
├─ Password length validation
├─ Name presence check
└─ Database constraint checks
    ↓ (Can't bypass, secure)

PASSWORD ENCRYPTION
├─ Bcrypt hashing
├─ Unique salt
└─ Slow by design
    ↓

DATABASE STORAGE
├─ Encrypted password stored
├─ Plain text email stored (needs to be searchable)
├─ User IP tracked
└─ Login history stored
    ↓

SESSION SECURITY
├─ HTTPS encryption
├─ HttpOnly cookie flag
├─ Session timeout
└─ CSRF token validation
```

---

## 📝 Validation Rules

### User Validation

```ruby
validates :name, :presence => true
validates :email, :presence => true
validates :email, :format => { :with => /.../ }
validates :email, :uniqueness => true
validates :password, :length => { :minimum => 6 }
validates :password_confirmation, :presence => true
```

### Account Validation

```ruby
validates :name, :presence => true
validates :name, :uniqueness => true
validates :locale_id, :presence => true
validates :default_rate, :numericality => { :allow_nil => true }
```

---

## 🔍 Data Verification Checklist

When a user signs up, here's what's verified:

- ✅ Name is not blank
- ✅ Email is valid format (user@domain.com)
- ✅ Email is unique (not already registered)
- ✅ Password is at least 6 characters
- ✅ Password confirmation matches
- ✅ Account name is not blank
- ✅ Account name is unique
- ✅ Language locale is selected
- ✅ All required fields are present
- ✅ Password is encrypted before saving
- ✅ No SQL injection
- ✅ No XSS attacks
- ✅ No CSRF attacks

---

## 🚀 After Sign-Up

User is automatically:

1. ✅ Logged in (session created)
2. ✅ Assigned to account (AccountUsers record created)
3. ✅ Made account admin (can manage other users)
4. ✅ Given example backlog (tutorial project)
5. ✅ Notified (admin gets email about new user)
6. ✅ Redirected to dashboard

---

## 🔐 Where Passwords Are NEVER Stored

- ❌ Logs
- ❌ Error messages
- ❌ Cookies (only session token)
- ❌ URLs (form post body instead)
- ❌ Database plain text
- ❌ Cache
- ❌ Browser history

---

## 📱 Session & Remember Me

### Regular Login
```
Session created during sign-up
└─ session[:user_id] = user.id
└─ Cookie: _session=...
└─ Expires: ~24 hours
```

### Remember Me (Optional)
```
If user checks "Remember me"
└─ Persistent token created
└─ Cookie: remember_user_token=...
└─ Expires: 2 weeks
└─ Auto-login on next visit
```

### Logout
```
Session destroyed
├─ session[:user_id] = nil
├─ Cookie deleted
└─ User must login again
```

---

## 🔗 Related Models & Relationships

```ruby
# User model
User
├─ has_many :account_users
├─ has_many :accounts (through account_users)
├─ has_many :backlogs (through backlog_users)
└─ validates :name, :presence => true

# Account model
Account
├─ has_many :account_users
├─ has_many :users (through account_users)
├─ has_many :backlogs
├─ belongs_to :locale
└─ validates :name, :uniqueness => true

# AccountUser model (Join)
AccountUser
├─ belongs_to :user
├─ belongs_to :account
└─ Tracks: admin status, privilege level
```

---

## 📚 Devise Modules Explained

| Module | What it Does |
|--------|--------------|
| `database_authenticatable` | Handles password validation & storage |
| `registerable` | Allows new user signup |
| `recoverable` | Password reset via email |
| `rememberable` | "Remember me" functionality |
| `trackable` | Tracks login history & IP |
| `validatable` | Validates email & password |
| `async` | Uses Sidekiq for emails |

---

## 🎯 Summary

**What:** easyBacklog uses Devise gem for authentication  
**How:** Bcrypt encryption, database storage, cookie sessions  
**Where:** Users table, Accounts table, AccountUsers join table  
**Why:** Industry-standard, secure, flexible  
**Result:** Secure multi-tenant SaaS with user accounts  

**Key Point:** Passwords are encrypted with Bcrypt (one-way) and never stored in plain text. Sessions are managed via cookies, and users can belong to multiple accounts with different roles.

