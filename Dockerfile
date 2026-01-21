# Dockerfile
FROM ruby:2.6-bullseye

# Install dependencies
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    postgresql-client \
    nodejs \
    npm \
    git \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy .ruby-version first (needed by Gemfile)
COPY .ruby-version ./

# Copy Gemfile
COPY Gemfile ./

# Configure git to use https instead of git protocol
RUN git config --global url."https://".insteadOf git://

# Install gems
RUN gem install bundler -v 1.17.3
# Install build dependencies needed for native extensions
RUN apt-get update && apt-get install -y --no-install-recommends \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*
RUN bundle install --no-deployment

# Copy the rest of the application
COPY . .

# Precompile assets (if needed)
# RUN bundle exec rake assets:precompile RAILS_ENV=production

# Expose port 3000
EXPOSE 3000

# Start the server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]