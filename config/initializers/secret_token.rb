# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.

# SECURITY: Secret token must be set via environment variable
# Generate a new token with: rake secret
secret = ENV['SECRET_KEY_BASE'] || ENV['SECRET_TOKEN']

if secret.blank?
  if Rails.env.production?
    raise "SECRET_KEY_BASE environment variable must be set in production"
  else
    # Fallback for development/test - should still be set in .env
    warn "WARNING: SECRET_KEY_BASE not set. Using insecure fallback for #{Rails.env} environment"
    secret = '1767515e3dcb83aa26da6392e1ecc039d327bb7f26c158321c486b4e0fe13a1f1d8629df5ad2be76ef72b08680674f63cb9d38d8bcc3e43b7f975afb0bb4fcec'
  end
end

EasyBacklog::Application.config.secret_token = secret
