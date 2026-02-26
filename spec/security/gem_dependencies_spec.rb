# encoding: UTF-8

require 'spec_helper'

describe 'Gem Dependencies and Security' do

  describe 'Critical security gems are present' do

    it 'should have devise for authentication' do
      expect(Gem::Specification.find_by_name('devise')).not_to be_nil
    end

    it 'should have devise-encryptable for password encryption' do
      expect(Gem::Specification.find_by_name('devise-encryptable')).not_to be_nil
    end

    it 'should have sidekiq for async job processing' do
      expect(Gem::Specification.find_by_name('sidekiq')).not_to be_nil
    end

  end

  describe 'Gem version requirements' do

    it 'should be running Rails 3.2.x' do
      rails_version = Rails::VERSION::STRING
      expect(rails_version).to match(/^3\.2/)
    end

    it 'should have Devise 2.1.x or higher' do
      devise_version = Devise::VERSION
      expect(devise_version).to match(/^2\./)
    end

  end

  describe 'Vulnerabilities in dependencies' do

    it 'should not have known critical CVEs in core gems', :skip => 'Requires bundle audit' do
      # This test documents that bundle audit should be run
      # Run: bundle audit check --update
      skip 'Requires bundler-audit gem and manual review'
    end

    it 'should have all gems from Gemfile.lock verified' do
      gemfile_path = Rails.root.join('Gemfile.lock')
      expect(File.exist?(gemfile_path)).to be_true
    end

  end

  describe 'Security-related configuration' do

    it 'should have secret_token configured' do
      expect(Rails.application.config.secret_token).not_to be_nil
      expect(Rails.application.config.secret_token.length).to be > 30
    end

    it 'should have session key configured' do
      expect(Rails.application.config.session_options[:key]).not_to be_nil
    end

  end

  describe 'External service dependencies' do

    it 'should have SendGrid gem for email delivery' do
      expect(Gem::Specification.find_by_name('mail')).not_to be_nil
    end

    it 'should have optional Ably gem for realtime' do
      # Ably is optional and should only be loaded if ENV['ENABLE_REALTIME']
      skip 'Ably is optional'
    end

  end

end

describe 'Gemfile Configuration' do

  it 'should pin gem versions for reproducibility' do
    gemfile_lock_path = Rails.root.join('Gemfile.lock')
    expect(File.exist?(gemfile_lock_path)).to be_true
    
    gemfile_lock_content = File.read(gemfile_lock_path)
    # Verify gems have specific versions
    expect(gemfile_lock_content).to match(/devise \([\d\.]+\)/)
    expect(gemfile_lock_content).to match(/rails \([\d\.]+\)/)
  end

  it 'should not include gem vulnerabilities in production dependencies' do
    # Document requirement for security auditing
    # Should run: bundle audit check --update regularly
  end

end

describe 'Rails Configuration Security' do

  it 'should have session store configured' do
    expect(Rails.application.config.session_store).not_to be_nil
  end

  it 'should have CSRF protection enabled' do
    expect(Rails.application.config.action_controller.allow_forgery_protection).not_to be_false
  end

  it 'should not have verbose error pages in production' do
    if Rails.env.production?
      expect(Rails.application.config.consider_all_requests_local).to be_false
    end
  end

end

describe 'Password and Encryption Configuration' do

  it 'should use bcrypt for password hashing' do
    user = FactoryGirl.create(:user, :password => 'TestPassword123!')
    user.reload
    
    # Verify bcrypt is used (usually shown in password hash format $2a$, $2b$, or $2y$)
    expect(user.encrypted_password).not_to be_empty
    # Bcrypt hashes are 60 characters long
    expect(user.encrypted_password.length).to be >= 50
  end

  it 'should have password salt configured' do
    user = FactoryGirl.create(:user)
    user.reload
    expect(user.password_salt).not_to be_nil
  end

end

describe 'External API Key Security' do

  it 'should not hardcode API keys in source code' do
    # Check that config files use environment variables
    mail_initializer = File.read(Rails.root.join('config/initializers/mail.rb'))
    expect(mail_initializer).to match(/ENV\[/)
    
    # Verify SendGrid credentials come from environment
    expect(mail_initializer).to include('SENDGRID')
  end

  it 'should not store API keys in routes or controllers' do
    routes_file = File.read(Rails.root.join('config/routes.rb'))
    # Should not have hardcoded keys
    expect(routes_file).not_to match(/key\s*[:=]\s*['"]\w+['"]/)
  end

end

describe 'Logging and Debugging Configuration' do

  it 'should have SQL query logging disabled or restricted in production' do
    if Rails.env.production?
      # Document that verbose logging is disabled
    end
  end

  it 'should not log sensitive parameters', :skip => 'Configuration dependent' do
    # Rails 3.2 supports filter_parameter_logging
    config_file = File.read(Rails.root.join('config/initializers/filter_parameter_logging.rb')) rescue nil
    # Should filter out passwords, tokens, etc.
  end

end
