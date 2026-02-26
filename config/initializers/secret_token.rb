# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
EasyBacklog::Application.config.secret_token = ENV['SECRET_TOKEN'] || begin
  if Rails.env.development? || Rails.env.test?
    # Generate a random token for development/test if not provided
    # This is safe as it's regenerated each restart in non-production envs
    SecureRandom.hex(64)
  else
    raise "ERROR: SECRET_TOKEN environment variable must be set in #{Rails.env} environment"
  end
end
