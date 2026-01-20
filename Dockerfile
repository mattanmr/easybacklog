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

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Configure git to use https instead of git protocol
RUN git config --global url."https://".insteadOf git://

# Install gems
RUN gem install bundler -v 1.17.3
# Pre-install json gem that's compatible with Ruby 2.6
RUN gem install json -v 2.3.0
RUN bundle install

# Copy the rest of the application
COPY . .

# Precompile assets (if needed)
# RUN bundle exec rake assets:precompile RAILS_ENV=production

# Expose port 3000
EXPOSE 3000

# Start the server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]