# easyBacklog Sign-Up Mechanism - Technical Deep Dive

**Date:** January 21, 2026  
**Framework:** Rails 3.2 + Devise 2.1.4  
**Purpose:** Complete explanation of authentication, data storage, and validation

---

## 1. Overview: How Sign-Up Works

```
User submits form
    ↓
Registration Controller validates data
    ↓
Creates User record (with encrypted password)
    ↓
Creates Account record (if account_setup=true)
    ↓
Links User & Account via AccountUsers join table
    ↓
Sets up example backlog & permissions
    ↓
User is logged in automatically (session created)
    ↓
Redirect to dashboard
```

---

## 2. Authentication Framework: Devise

### What is Devise?

**Devise** is a flexible authentication solution for Rails that provides:
- User registration (sign up)
- User authentication (sign in/out)
- Password recovery
- Session management
- User tracking (sign-in count, IPs, timestamps)

**Version Used:** 2.1.4 (Devise-async for background email delivery)

### Devise Modules Enabled

In the User model (`app/models/user.rb`):

```ruby
devise :database_authenticatable, :registerable,
       :recoverable, :rememberable, :trackable, :validatable,
       :async  # Uses Sidekiq for async email delivery
```

| Module | Purpose |
|--------|---------|
| `:database_authenticatable` | Encrypts & compares passwords, validates credentials |
| `:registerable` | Allows users to register (sign up) |
| `:recoverable` | Provides password reset via email |
| `:rememberable` | "Remember me" functionality for persistent login |
| `:trackable` | Tracks sign-in count, current & last sign-in timestamps, IPs |
| `:validatable` | Validates email format, password strength, presence |
| `:async` | Sends confirmation emails asynchronously via Sidekiq |

---

## 3. Data Storage: Database Tables

### Users Table

Stores individual user credentials and authentication metadata:

```sql
CREATE TABLE users (
  id                      INTEGER PRIMARY KEY,
  name                    VARCHAR(255) NOT NULL,
  email                   VARCHAR(255) NOT NULL,
  encrypted_password      VARCHAR(128) NOT NULL,          -- Bcrypt encrypted
  password_salt           VARCHAR(255),                   -- Salt for password hashing
  confirmation_token      VARCHAR(255),                   -- Email verification token
  confirmed_at            TIMESTAMP,                      -- When email was confirmed
  confirmation_sent_at    TIMESTAMP,                      -- When confirmation email was sent
  reset_password_token    VARCHAR(255),                   -- Password reset token
  reset_password_sent_at  TIMESTAMP,                      -- When reset email sent
  remember_created_at     TIMESTAMP,                      -- "Remember me" token creation
  sign_in_count           INTEGER DEFAULT 0,              -- How many times user logged in
  current_sign_in_at      TIMESTAMP,                      -- When user last logged in
  last_sign_in_at         TIMESTAMP,                      -- Previous login timestamp
  current_sign_in_ip      VARCHAR(255),                   -- IP of current session
  last_sign_in_ip         VARCHAR(255),                   -- IP of last session
  admin_rights            BOOLEAN,                        -- Is user a system admin?
  created_at              TIMESTAMP,                      -- Account creation time
  updated_at              TIMESTAMP                       -- Last modification time
);
```

**Key Security Features:**
- ✅ Password is **encrypted** (not stored as plain text)
- ✅ Password salt for additional security
- ✅ Tokens for password reset and email confirmation
- ✅ IP tracking for security auditing
- ✅ Sign-in tracking for activity monitoring

### Accounts Table

Stores organization/team information that users belong to:

```sql
CREATE TABLE accounts (
  id                    INTEGER PRIMARY KEY,
  name                  VARCHAR(255) NOT NULL,
  locale_id             INTEGER,                   -- Language preference
  default_velocity      DECIMAL,                   -- Default sprint velocity
  default_rate          INTEGER,                   -- Default day rate for costing
  default_use_50_90     BOOLEAN,                   -- Use 50/90 estimation method?
  scoring_rule_id       INTEGER,                   -- Fibonacci or other scoring
  defaults_set          BOOLEAN,                   -- Have defaults been configured?
  created_at            TIMESTAMP,
  updated_at            TIMESTAMP
);
```

**Purpose:**
- Container for backlogs, sprints, stories
- Settings shared across the account
- Multi-tenant model (each account is isolated)

### Join Table: AccountUsers

Links users to accounts with role/privilege information:

```sql
CREATE TABLE account_users (
  id          INTEGER PRIMARY KEY,
  account_id  INTEGER NOT NULL,   -- Which account
  user_id     INTEGER NOT NULL,   -- Which user
  admin       BOOLEAN NOT NULL,   -- Is this user an account admin?
  privilege   VARCHAR(255),       -- Role: full, read, limited
  created_at  TIMESTAMP,
  updated_at  TIMESTAMP
);
```

**Purpose:**
- Enables many-to-many relationship between Users and Accounts
- Users can belong to multiple accounts
- Each user has a role/privilege in each account
- Tracks admin status per account

### Related Tables Used During Sign-Up

**Locales Table** (for language preference):
```sql
CREATE TABLE locales (
  id        INTEGER PRIMARY KEY,
  name      VARCHAR(255),  -- "English (United States)"
  code      VARCHAR(10),   -- "en_US"
  position  INTEGER        -- Sort order
);
```

---

## 4. The Sign-Up Process: Step-by-Step

### Step 1: User Visits Sign-Up Page

**Route:** `GET /users/sign_up`  
**Controller:** `Devise::RegistrationsController#new`

```ruby
def new
  build_resource({})
  @account = Account.new
  resource = build_resource({})
  respond_with resource
end
```

**What happens:**
- Empty User object created
- Empty Account object created
- Form rendered with fields

---

### Step 2: User Submits Form

**Route:** `POST /users`  
**Controller:** `Devise::RegistrationsController#create`

**Form Data Submitted:**
```
POST /users/sign_up

Body:
{
  "user": {
    "name": "Dev Test",
    "email": "test@example.com",
    "password": "securepassword123",
    "password_confirmation": "securepassword123"
  },
  "account": {
    "name": "devtest",
    "locale_id": "1"     # English (United States)
  },
  "show_account_setup": "true"
}
```

---

### Step 3: Validation

**User Model Validations:**
```ruby
class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable, ...
  
  validates_presence_of :name
  # Devise provides additional validations:
  # - Email format validation
  # - Email uniqueness
  # - Password length (minimum 6 characters)
  # - Password confirmation match
end
```

**Account Model Validations:**
```ruby
class Account < ActiveRecord::Base
  validates_uniqueness_of :name        # No duplicate account names
  validates_presence_of :name, :locale # Both required
  validates_numericality_of :default_rate, :default_velocity
end
```

**All validations run in a database transaction:**
```ruby
Account.transaction do
  # Both user and account must be valid
  # If either fails, entire transaction rolls back
end
```

---

### Step 4: Password Encryption

**Before saving, Devise encrypts the password:**

```
Password entered: "securepassword123"
         ↓ (Bcrypt algorithm)
Encrypted: "$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcg7b3XeKeUxWdeS86E36P4/LlK"
         ↓
Stored in database: encrypted_password field
Salt: Also stored (used during encryption)
```

**Why Bcrypt?**
- Slow by design (protects against brute force)
- One-way function (can't decrypt)
- Uses salt (prevents rainbow table attacks)
- Industry standard

---

### Step 5: Create User Record

```ruby
# Create in users table
User.create!(
  name: "Dev Test",
  email: "test@example.com",
  encrypted_password: "$2a$10$...",  # Bcrypt encrypted
  password_salt: "...",
  sign_in_count: 0,
  admin_rights: false
)
```

---

### Step 6: Create Account Record

```ruby
# If user is setting up a new account (show_account_setup=true)
Account.create!(
  name: "devtest",
  locale_id: 1,  # English (United States)
  defaults_set: false
)
```

---

### Step 7: Link User to Account

```ruby
# Create record in account_users join table
AccountUser.create!(
  user_id: new_user.id,
  account_id: new_account.id,
  admin: true,          # Account creator is admin
  privilege: "full"     # Full access to all features
)
```

**At this point:**
```
users table:           account_users table:      accounts table:
[ID:1, User Data]  ←→  [User:1, Account:1]  ←→  [ID:1, Account Data]
                           admin: true
                           privilege: full
```

---

### Step 8: Setup Account for User

```ruby
# Called: @account.setup_account_for_user(user)
# This method:
# 1. Creates example backlog for new account
# 2. Grants user explicit read/write permissions
# 3. Sets up default backlog structure
```

---

### Step 9: Create Session & Log In User

```ruby
# Devise creates session after successful registration
sign_in(resource_name, resource)

# Sets:
# - Session[:user_id] = user.id
# - User is now authenticated
# - Can access protected pages
```

---

### Step 10: Redirect & Success

```ruby
# Redirect to dashboard
redirect_to after_update_path_for(resource)

# Flash message shown
flash[:notice] = 'Your new account has been created for you'

# Background job queued
UsersNotifier.delay.new_user(user.id, account.id)
# Sends notification email to admin about new user
```

---

## 5. Authentication & Sessions

### Session Storage

**Where:** In-memory session store (can be configured for Redis)

```ruby
# When user logs in, session is created
Session {
  session_id: "abc123xyz...",
  user_id: 1,
  created_at: 2026-01-21 18:00:00
}
```

### Session Persistence

**Browser Cookie:**
```
Cookie: _easybacklog_session=abc123xyz
Stored in browser (sent with every request)
```

### Authentication Check

**On each request, Rails checks:**
```ruby
current_user = User.find_by_id(session[:user_id])

if current_user.present?
  # User is authenticated ✅
  # Can access protected pages
else
  # User is not authenticated ❌
  # Redirect to login
end
```

### Persistent Login ("Remember Me")

**What happens when user checks "Remember me":**
```ruby
# Devise creates a remember token
remember_token = SecureRandom.base64(15)

# Stored in database
user.update(:remember_created_at => Time.now)

# Stored in browser cookie (long expiration, e.g., 2 weeks)
Cookie: remember_user_token=xyz789
```

**On next visit:**
```
Browser cookie checked
     ↓
If valid remember_token found
     ↓
User is automatically logged in
     ↓
Session created
     ↓
No login page needed
```

---

## 6. Data Validation During Sign-Up

### Client-Side Validation

**JavaScript validation** (from `register_and_account.js`):
- Email format check
- Password strength validation
- Field presence check
- Real-time feedback to user

### Server-Side Validation (REQUIRED)

**Rails validates everything again:**

```ruby
# User model validation
class User < ActiveRecord::Base
  validates :email, :presence => true
  validates :email, :uniqueness => true
  validates :password, :length => { :minimum => 6 }
  validates :name, :presence => true
end

# Account model validation
class Account < ActiveRecord::Base
  validates :name, :presence => true
  validates :name, :uniqueness => true
  validates :locale_id, :presence => true
end
```

### Why Both Client & Server?

| Validation | Purpose |
|-----------|---------|
| Client-side | Fast user feedback, better UX |
| Server-side | Security - cannot be bypassed by hacker |

**Example attack prevented:**
```
Hacker sends POST request directly (bypasses form)
    ↓
With invalid email or duplicate email
    ↓
Server-side validation catches it
    ↓
Request rejected
    ↓
Invalid data never saved to database ✅
```

---

## 7. Security Features

### Password Security

✅ **Bcrypt Encryption:**
- One-way hashing (passwords can't be decrypted)
- Salted (each password different even if same text)
- Slow by design (resists brute force)

✅ **Password Reset:**
- User can reset via email link
- Token expires after time limit
- Old password not needed (but new one required)

### Session Security

✅ **HTTPS Only:** Cookies transmitted encrypted  
✅ **HttpOnly Flag:** JavaScript can't access session cookie  
✅ **Session Timeout:** Sessions expire after inactivity  
✅ **CSRF Protection:** Tokens prevent cross-site attacks  

### Account Security

✅ **Email Verification:** New account emails can be verified  
✅ **IP Tracking:** Tracks where user logs in from  
✅ **Admin Rights:** Limited to designated admins  
✅ **Role-Based Access:** Users have privilege levels  

---

## 8. Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    SIGN-UP PROCESS                          │
└─────────────────────────────────────────────────────────────┘

BROWSER                          SERVER                    DATABASE
────────────────────────────────────────────────────────────────

User fills form
   │
   ├─ Name: "Dev Test"
   ├─ Email: "dev@test.com"
   ├─ Password: "pass123"
   ├─ Account: "devtest"
   └─ Locale: "English"
        │
        ├─ POST /users/sign_up ─────→ RegistrationsController#create
        │                                      │
        │                                      ├─ Validate User
        │                                      ├─ Validate Account
        │                                      ├─ Encrypt password (Bcrypt)
        │                                      │
        │                                      ├─ INSERT into users ─────────→ ✓ Created
        │                                      │
        │                                      ├─ INSERT into accounts ─────→ ✓ Created
        │                                      │
        │                                      ├─ INSERT into account_users ─→ ✓ Link created
        │                                      │
        │                                      ├─ Setup example backlog
        │                                      │
        │                                      ├─ Create session
        │                                      │
        │ ←─────── Set-Cookie ─────────────────┤
        │ _session: abc123xyz
        │
   ├─ Flash message
   ├─ Redirect to dashboard
   └─ User is logged in ✅

DATABASE STATE:
┌──────────────────────────────────────────────────────────────┐
│ users                   │ accounts            │ account_users │
│ ─────────────────────── │ ─────────────────── │ ──────────── │
│ ID: 1                   │ ID: 1               │ ID: 1        │
│ name: Dev Test          │ name: devtest       │ user_id: 1   │
│ email: dev@test.com     │ locale_id: 1       │ account_id:1 │
│ encrypted_password: ... │ created_at: ...     │ admin: true  │
│ sign_in_count: 0        │                     │ privilege: .. │
│ created_at: ...         │                     │              │
└──────────────────────────────────────────────────────────────┘
```

---

## 9. API Reference: Key Methods

### User Authentication

```ruby
# Check if user is logged in
current_user  # Returns User object or nil

# Check if logged in
user_signed_in?  # Returns true/false

# Sign out user
sign_out

# Require authentication (before filter)
before_filter :authenticate_user!
```

### Password Handling

```ruby
# Check password (for login)
user.valid_password?(password_string)

# Update password
user.update_with_password(params[:user])

# Send password reset email
user.send_reset_password_instructions
```

### Session Management

```ruby
# Create session after signup
sign_in(resource_name, resource)

# Create with remember me
sign_in(resource_name, resource, bypass: true)

# Check remember token
user.remember_created_at.present?
```

---

## 10. Complete Request Flow Diagram

```
REQUEST → Router matches POST /users → RegistrationsController
            │
            ├─ Build Resource (User)
            │
            ├─ Transaction START
            │    ├─ Validate User
            │    │  └─ Check email format ✓
            │    │  └─ Check email uniqueness ✓
            │    │  └─ Check password length ✓
            │    │  └─ Check name present ✓
            │    │
            │    ├─ Save User
            │    │  └─ Encrypt password with Bcrypt
            │    │  └─ INSERT into users table
            │    │
            │    ├─ Validate Account
            │    │  └─ Check name present ✓
            │    │  └─ Check locale_id present ✓
            │    │  └─ Check name unique ✓
            │    │
            │    ├─ Save Account
            │    │  └─ INSERT into accounts table
            │    │
            │    ├─ Create AccountUsers Link
            │    │  └─ INSERT into account_users table
            │    │  └─ Set admin: true
            │    │
            │    ├─ Setup Account
            │    │  └─ Create example backlog
            │    │  └─ Grant user permissions
            │    │
            │    └─ Transaction COMMIT ✓
            │
            ├─ Create Session
            │  └─ session[:user_id] = user.id
            │
            ├─ Send Flash Message
            │  └─ "Your new account has been created for you"
            │
            ├─ Queue Background Job
            │  └─ Send notification email to admin
            │
            └─ RESPONSE → Redirect to dashboard
                          Set-Cookie: _session=...
```

---

## 11. Summary: What Gets Stored Where

| Data | Table | Field | Encrypted? |
|------|-------|-------|-----------|
| Name | users | name | ❌ No |
| Email | users | email | ❌ No |
| Password | users | encrypted_password | ✅ Yes (Bcrypt) |
| Sign-in count | users | sign_in_count | ❌ No |
| Session token | (Memory) | - | ✅ Yes (over HTTPS) |
| Account name | accounts | name | ❌ No |
| Language choice | accounts | locale_id | ❌ No |
| User-to-Account link | account_users | user_id, account_id | ❌ No |
| User role | account_users | privilege | ❌ No |
| IP address | users | current_sign_in_ip | ❌ No |
| Login timestamp | users | current_sign_in_at | ❌ No |

---

## 12. Key Takeaways

✅ **Authentication:** Devise handles everything (register, login, password reset, sessions)

✅ **Data Storage:** 
- Users in `users` table
- Organizations in `accounts` table  
- Links in `account_users` table (many-to-many)

✅ **Password Security:**
- Bcrypt encryption (one-way, salted, slow)
- Never stored in plain text
- Can be reset via email

✅ **Validation:**
- Client-side: Fast feedback
- Server-side: Security (can't be bypassed)

✅ **Sessions:**
- Created after login
- Stored in browser cookie
- User ID checked on each request
- Can be persistent ("Remember me")

✅ **Multi-tenant:**
- One user can belong to multiple accounts
- Each user has a role per account
- Account data is isolated

