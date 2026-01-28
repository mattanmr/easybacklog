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
    # Fallback for development/test - generate a random secret if not set
    # IMPORTANT: This is only for development/test. Never use in production.
    warn "WARNING: SECRET_KEY_BASE not set. Using randomly generated secret for #{Rails.env} environment"
    warn "         Set SECRET_KEY_BASE in your .env file to suppress this warning"
    secret = SecureRandom.hex(64)
  end
end

EasyBacklog::Application.config.secret_token = secret
