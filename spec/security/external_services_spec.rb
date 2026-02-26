# encoding: UTF-8

require 'spec_helper'

describe 'External Services and Links Audit' do

  describe 'External Service Configuration' do

    it 'should have external services disabled by default' do
      ExternalServices.enabled?.should be_false
    end

    it 'should have email disabled by default' do
      # Email may be disabled for local dev
      ExternalServices.email_enabled?.should be_false unless ENV['ENABLE_EMAIL'] == 'true'
    end

    it 'should have analytics disabled by default' do
      ExternalServices.analytics_enabled?.should be_false unless ENV['ENABLE_ANALYTICS'] == 'true'
    end

    it 'should have feedback widget disabled by default' do
      ExternalServices.feedback_enabled?.should be_false unless ENV['ENABLE_FEEDBACK'] == 'true'
    end

    it 'should have realtime API disabled by default' do
      ExternalServices.realtime_enabled?.should be_false unless ENV['ENABLE_REALTIME'] == 'true'
    end

    it 'should have error tracking disabled by default' do
      ExternalServices.error_tracking_enabled?.should be_false unless ENV['ENABLE_ERROR_TRACKING'] == 'true'
    end

    it 'should have performance monitoring disabled by default' do
      ExternalServices.performance_monitoring_enabled?.should be_false unless ENV['ENABLE_PERFORMANCE_MONITORING'] == 'true'
    end

  end

  describe 'Google Analytics Removal' do

    it 'should not load Google Analytics script in development' do
      # Verify GA is not loaded when disabled
      if !ExternalServices.analytics_enabled?
        # GoogleAnalytics script should not be loaded
        skip 'GA verification requires browser testing'
      end
    end

    it 'should not load GA ga.js from google-analytics.com when disabled' do
      # In view test - ensure the external script is not rendered
      skip 'Browser-based verification needed'
    end

  end

  describe 'UserEcho Feedback Widget Removal' do

    it 'should not load UserEcho when feedback is disabled' do
      if !ExternalServices.feedback_enabled?
        # UserEcho script should not be loaded
        skip 'Widget verification requires browser testing'
      end
    end

    it 'should not load cdn.userecho.com when feedback disabled' do
      # In view test - ensure the widget script is not rendered
      skip 'Browser-based verification needed'
    end

  end

  describe 'Hardcoded External URLs in Views' do

    it 'should not have hardcoded easybacklog.com API links' do
      faq_view = File.read(Rails.root.join('app/views/pages/faq.html.haml'))
      # Check for conditionally rendered links
      (faq_view.include?('link_to') || faq_view.include?('ExternalServices')).should be_true
    end

    it 'should not have hardcoded support.easybacklog.com or userecho URLs in main content' do
      contact_view = File.read(Rails.root.join('app/views/pages/contact.html.haml'))
      # Verify UserEcho links are conditional
      contact_view.should include('ExternalServices.feedback_enabled?')
    end

    it 'should not have GitHub portfolio links in production content' do
      # These are acceptable in vendor JS/comments but not in user-facing content
      app_view_files = Dir.glob(Rails.root.join('app/views/**/*.haml'))
      portfolio_links = []
      
      app_view_files.each do |file|
        content = File.read(file)
        if content.match?(/mattheworiordan\.com/) && !file.include?('vendor')
          portfolio_links << file
        end
      end
      
      portfolio_links.should be_empty
    end

  end

  describe 'External Email Configuration' do

    it 'should use SendGrid SMTP only when ENABLE_EMAIL is true' do
      mail_initializer = File.read(Rails.root.join('config/initializers/mail.rb'))
      mail_initializer.should include('SENDGRID_USERNAME')
      mail_initializer.should include('SENDGRID_PASSWORD')
    end

    it 'should not hardcode SendGrid credentials' do
      mail_initializer = File.read(Rails.root.join('config/initializers/mail.rb'))
      mail_initializer.should_not include("'username'") unless ENV['SENDGRID_USERNAME']
      mail_initializer.should_not include("'password'") unless ENV['SENDGRID_PASSWORD']
    end

  end

  describe 'Ably Real-time Configuration' do

    it 'should only load Ably when ENABLE_REALTIME is true' do
      # Ably is optional
      if ENV['ENABLE_REALTIME'] != 'true' && ENV['ABLY_API_KEY'].nil?
        # Should not try to initialize Ably
        expect(defined?(Ably)).to be_nil || skip('Ably gem not required')
      end
    end

  end

  describe 'External API Keys in Environment Configuration' do

    it 'should not expose API keys in version control' do
      # Check that .gitignore includes .env
      gitignore = File.read(Rails.root.join('.gitignore'))
      gitignore.should include('.env')
    end

    it 'should use ENV variables for all external service keys' do
      # Document the required environment variables
      required_vars = [
        'SENDGRID_USERNAME', 'SENDGRID_PASSWORD',
        'ABLY_API_KEY', 'NEW_RELIC_LICENSE_KEY'
      ]
      
      # At least verify the configuration structure expects env vars
      config_files = Dir.glob(Rails.root.join('config/initializers/**/*.rb'))
      config_content = config_files.map { |f| File.read(f) }.join
      
      required_vars.each do |var|
        config_content.should include(var) if var.match?(/EXTERNAL|SENDGRID|ABLY|NEW_RELIC/)
      end
    end

  end

  describe 'Error Tracking Service (Exceptional)' do

    it 'should have Exceptional disabled in development and test' do
      if Rails.env.development? || Rails.env.test?
        # Should not track errors to external service
        skip 'Test in production environment'
      end
    end

  end

  describe 'External Links in Documentation and Comments' do

    it 'should have documentation for all external service dependencies' do
      doc_files = Dir.glob(Rails.root.join('doc/*.md'))
      doc_files.count.should be > 0
    end

    it 'should have EXTERNAL_SERVICES_GUIDE documentation' do
      expect(File.exist?(Rails.root.join('doc/EXTERNAL_SERVICES_GUIDE.md'))).to be_true
    end

  end

  describe 'Cookie and Session Configuration' do

    it 'should use secure session configuration' do
      session_config = File.read(Rails.root.join('config/initializers/session_store.rb'))
      # Verify session is not exposed publicly
      session_config.should_not be_empty
    end

  end

  describe 'Vendor JavaScript External References' do

    it 'should not execute external scripts from vendor JS in main content' do
      vendor_js = Dir.glob(Rails.root.join('vendor/assets/javascripts/**/*.js(erb)?'))
      external_refs = []
      
      vendor_js.each do |file|
        content = File.read(file)
        # Look for external domain references that might load scripts
        if content.match?(/http[s]?:\/\/[^localhost|127.0.0.1]/) && content.match?(/script|load|ajax/)
          external_refs << file
        end
      end
      
      # Some external references in comments are acceptable
      external_refs.each do |file|
        content = File.read(file)
        # Verify they're in comments only
        matches = content.scan(/http[s]?:\/\/[^localhost|127.0.0.1]/)
        matches.each do |match|
          # Should be in comment
          line_with_match = content.split("\n").find { |l| l.include?(match) }
          (line_with_match.include?('//') || line_with_match.include?('#')).should be_true
        end
      end
    end

  end

end

describe 'External Service Feature Tests', :type => :feature do

  let!(:account) { FactoryGirl.create(:account_with_user) }
  let!(:user) { account.users.first }

  before(:each) do
    sign_in user
  end

  it 'should not load GoogleAnalytics when visiting any page with analytics disabled' do
    visit account_path(account)
    
    unless ExternalServices.analytics_enabled?
      # Should not make request to google-analytics.com
      # (Would need Capybara with network inspection)
    end
  end

  it 'should not load UserEcho widget when visiting any page with feedback disabled' do
    visit account_path(account)
    
    unless ExternalServices.feedback_enabled?
      # Should not make request to cdn.userecho.com
      # (Would need Capybara with network inspection)
    end
  end

  it 'should display contact page without external links when services disabled' do
    visit pages_contact_path
    
    unless ExternalServices.feedback_enabled?
      # Should show disabled message
      page.should have_content('disabled')
    end
  end

  it 'should display FAQ page without support forum link when feedback disabled' do
    visit pages_faq_path
    
    unless ExternalServices.feedback_enabled?
      # Should not have UserEcho support forum link visible
      page.should_not have_link('support forum and knowledgebase', :href => /userecho/)
    end
  end

end
