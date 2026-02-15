# Dockerfile for easyBacklog
# ==================================================================
# This Dockerfile creates a container for running the easyBacklog
# Rails 3.2 application. It's designed for students to learn about
# containerizing legacy Rails applications.
# ==================================================================

# Base Image: Ruby 2.6.10 on Debian Bullseye
# - Ruby 2.6 is required for Rails 3.2 compatibility
# - Bullseye provides updated system libraries while maintaining stability
# - This version balances legacy gem support with modern tooling
FROM ruby:2.6.10-bullseye

# Install System Dependencies
# ------------------------------------------------
# postgresql-client: Required for database interactions
# nodejs & npm: Required for asset pipeline and JavaScript runtime
# git: Needed for gems that install from git repositories
# build-essential: Provides gcc, g++, make for compiling native gem extensions
# libpq-dev: PostgreSQL development headers for the 'pg' gem
# 
# The --no-install-recommends flag keeps the image smaller by skipping
# unnecessary packages. We clean up apt cache at the end to reduce image size.
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    postgresql-client \
    nodejs \
    npm \
    git \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Set Working Directory
# ------------------------------------------------
# All subsequent commands will run in /app inside the container
WORKDIR /app

# Copy Dependency Files First
# ------------------------------------------------
# Docker builds images in layers. By copying only dependency files first,
# we can cache the gem installation layer. If Gemfile hasn't changed,
# Docker reuses the cached layer, making rebuilds much faster.
#
# .ruby-version: Specifies Ruby version (some gems read this)
# Gemfile & Gemfile.lock: Define all Ruby gem dependencies
COPY .ruby-version ./
COPY Gemfile Gemfile.lock ./

# Configure Git Protocol
# ------------------------------------------------
# Some gems use git:// protocol which is deprecated and often blocked.
# This converts all git:// URLs to https:// automatically.
RUN git config --global url."https://".insteadOf git://

# Install Bundler
# ------------------------------------------------
# Bundler 1.17.3 is the last version compatible with Ruby 2.6 and Rails 3.2
RUN gem install bundler -v 1.17.3

# Install Additional Build Dependencies
# ------------------------------------------------
# Some gems (like Nokogiri) need XML parsing libraries for native extensions
# libxml2-dev & libxslt1-dev: Required for Nokogiri gem
# zlib1g-dev: Compression library needed by various gems
RUN apt-get update && apt-get install -y --no-install-recommends \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Ruby Gems
# ------------------------------------------------
# --jobs=4: Install gems in parallel for speed (uses 4 threads)
# --retry=3: Retry failed downloads up to 3 times
# --no-deployment: Allows installing dev/test gems (needed for testing in container)
#
# This step is expensive (2-3 minutes first time) but cached if Gemfile unchanged
RUN bundle install --jobs=4 --retry=3 --no-deployment

# Copy Application Code
# ------------------------------------------------
# Copy all application files into the container.
# This happens AFTER gem installation so code changes don't invalidate
# the gem cache layer (Docker layer optimization).
COPY . .

# Precompile Assets (Optional - Disabled for Development)
# ------------------------------------------------
# In production, you'd precompile assets (CSS, JS) for better performance.
# We skip this in development mode to allow dynamic reloading.
# Uncomment this line for production deployments:
# RUN bundle exec rake assets:precompile RAILS_ENV=production

# Expose Port 3000
# ------------------------------------------------
# This documents that the container listens on port 3000.
# The actual port mapping is configured in docker-compose.yml
EXPOSE 3000

# Start the Rails Server
# ------------------------------------------------
# Default command when container starts. This runs the Rails development server.
# -b 0.0.0.0: Bind to all interfaces (required for Docker networking)
#
# Note: docker-compose.yml can override this CMD with a different command
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]