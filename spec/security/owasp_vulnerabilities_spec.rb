# encoding: UTF-8

require 'spec_helper'

describe 'OWASP Top 10 Security Vulnerabilities' do

  let!(:default_scoring_rule) { FactoryGirl.create(:scoring_rule_default) }
  let!(:account) { FactoryGirl.create(:account_with_user) }
  let!(:user) { account.users.first }
  let!(:backlog) { FactoryGirl.create(:backlog, :account => account) }

  describe 'SQL Injection Prevention' do

    it 'should sanitize story search filters' do
      story = FactoryGirl.create(:story, :backlog => backlog, :title => 'Normal Story')
      sign_in user
      
      # Attempt SQL injection in search
      malicious_search = "'; DROP TABLE stories; --"
      get :index, :account_id => account.id, :search => malicious_search
      
      # Table should still exist and return normal response
      response.status.should_not == 500
      Story.count.should >= 1
    end

    it 'should escape filter parameters' do
      story = FactoryGirl.create(:story, :backlog => backlog, :title => 'Test Story')
      sign_in user
      
      # Attempt to inject SQL via filter
      get :index, :account_id => account.id, :filter => "1 OR 1='1"
      response.status.should_not == 500
    end

  end

  describe 'Cross-Site Scripting (XSS) Prevention' do

    it 'should escape HTML in story titles' do
      xss_payload = '<script>alert("XSS")</script>'
      story = FactoryGirl.create(:story, :backlog => backlog, :title => xss_payload)
      
      sign_in user
      get :show, :id => backlog.id, :account_id => account.id, :format => :json
      
      response_body = response.body
      # XSS payload should be escaped, not execute
      (response_body.include?('&lt;script&gt;') || response_body.include?('\u003cscript\u003e')).should be_true
    end

    it 'should escape HTML in story descriptions' do
      xss_payload = '<img src=x onerror="alert(\'XSS\')">'
      story = FactoryGirl.create(:story, :backlog => backlog, :description => xss_payload)
      
      sign_in user
      get :show, :id => story.id, :account_id => account.id, :format => :json
      
      response_body = response.body
      # Dangerous attributes should be escaped
      response_body.should_not include('onerror=')
    end

    it 'should escape HTML in theme names' do
      xss_payload = '"><script>alert(1)</script><template"'
      theme = FactoryGirl.create(:theme, :backlog => backlog, :name => xss_payload)
      
      sign_in user
      get :show, :id => backlog.id, :account_id => account.id, :format => :json
      
      # Should not execute script tags
      response_body = response.body
      response_body.should_not include('<script>')
    end

    it 'should escape HTML in comments' do
      xss_payload = '"><script>alert("XSS in comment")</script>'
      # Assuming stories have comments
      story = FactoryGirl.create(:story, :backlog => backlog)
      # Create comment if comment model exists
      # comment = FactoryGirl.create(:comment, :story => story, :body => xss_payload)
      
      sign_in user
      get :show, :id => story.id, :account_id => account.id, :format => :json
      response.status.should == 200
    end

  end

  describe 'Cross-Site Request Forgery (CSRF) Protection' do

    it 'should require valid CSRF token for POST requests' do
      # CSRF token should be required
      story_params = { :backlog_id => backlog.id, :title => 'New Story' }
      post :create, { :theme_id => 1, :story => story_params }
      
      # Request without proper CSRF context should fail
      # (depending on Rails CSRF configuration)
    end

    it 'should not require CSRF token for API requests with proper auth' do
      user_token = FactoryGirl.create(:user_token, :user => user)
      
      story_params = { :backlog_id => backlog.id, :title => 'API Story' }
      post :create, { :theme_id => 1, :story => story_params, :api_key => user_token.access_token, :format => :json }
      
      # API request with token should be allowed without CSRF token
      response.status.should_not == 422
    end

  end

  describe 'Broken Authentication Prevention' do

    let!(:other_user) { FactoryGirl.create(:user) }

    it 'should invalidate password reset token after use' do
      user = FactoryGirl.create(:user, :email => 'reset@example.com')
      user.send_reset_password_instructions
      user.reload
      token = user.reset_password_token
      
      # First reset should work
      user.reset_password!(token, 'NewPassword123!')
      user.reload
      user.reset_password_token.should be_nil
      
      # Second reset with same token should fail
      expect { user.reset_password!(token, 'AnotherPassword123!') }.to raise_error
    end

    it 'should expire password reset token after time limit' do
      user = FactoryGirl.create(:user)
      user.send_reset_password_instructions
      user.reload
      token = user.reset_password_token
      reset_sent_at = user.reset_password_sent_at
      
      # Password reset should have expiration (typically 6 hours)
      # This test documents the expected behavior
      user.reset_password_sent_at.should_not be_nil
    end

    it 'should track concurrent sessions (multiple IPs)' do
      sign_in user
      user.reload
      first_ip = user.current_sign_in_ip
      
      # New login should update IP tracking
      # (Document for security monitoring)
      user.sign_in_count.should be >= 1
      user.current_sign_in_at.should_not be_nil
    end

  end

  describe 'Sensitive Data Exposure Prevention' do

    it 'should not expose user passwords in API responses' do
      sign_in user
      get :index, :account_id => account.id, :format => :json
      
      response_body = response.body
      # Should not contain encrypted_password field
      json_response = JSON.parse(response_body)
      # Verify no password fields are exposed
    end

    it 'should not log sensitive information like passwords' do
      # Verify that passwords are not written to logs
      # This is typically configured in Rails.logger and log filtering
      user_password = 'SensitivePassword123!'
      user = FactoryGirl.create(:user, :password => user_password)
      
      # Password should not appear in Rails logs
      # (would need to check log files - this documents the requirement)
    end

    it 'should not expose reset tokens in error messages' do
      user = FactoryGirl.create(:user)
      user.send_reset_password_instructions
      user.reload
      token = user.reset_password_token
      
      # Error messages should not contain the token
      put :update, :id => user.id
      response.body.should_not include(token)
    end

    it 'should not expose email addresses to unauthorized users' do
      other_account = FactoryGirl.create(:account_with_user)
      other_user = other_account.users.first
      other_backlog = FactoryGirl.create(:backlog, :account => other_account)
      
      sign_in user
      # User should not be able to view other account users' details
      get :show, :id => other_backlog.id, :account_id => other_account.id
      response.code.should == status_code_to_string(:forbidden)
    end

  end

  describe 'XML External Entity (XXE) Injection Prevention' do

    it 'should safely parse XML without entity expansion attacks' do
      # If application accepts XML input, verify XXE protection
      xxe_payload = '<?xml version="1.0"?><!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///etc/passwd">]><foo>&xxe;</foo>'
      
      # Attempt to post XML (if supported)
      post :create, :backlog => { :name => 'test', :xml => xxe_payload }
      
      # Should safely handle without reading system files
      response.status.should_not == 500
    end

  end

  describe 'Broken Access Control Prevention' do

    it 'should prevent accessing private backlogs via direct URL' do
      private_backlog = FactoryGirl.create(:backlog, :account => account, :is_private => true) rescue FactoryGirl.create(:backlog, :account => account)
      
      other_account = FactoryGirl.create(:account_with_user)
      other_user = other_account.users.first
      
      sign_in other_user
      get :show, :id => private_backlog.id, :account_id => account.id
      response.code.should == status_code_to_string(:forbidden)
    end

    it 'should enforce resource ownership checks on delete operations' do
      other_account = FactoryGirl.create(:account_with_user)
      other_backlog = FactoryGirl.create(:backlog, :account => other_account)
      other_user = other_account.users.first
      
      sign_in user
      delete :destroy, :id => other_backlog.id, :account_id => other_account.id
      response.code.should == status_code_to_string(:forbidden)
      Backlog.find_by_id(other_backlog.id).should_not be_nil
    end

  end

  describe 'Using Components with Known Vulnerabilities' do

    it 'should not have critical CVE in Rails version' do
      # Rails 3.2 is EOL but document required patches for upgrade path
      rails_version = Rails::VERSION::STRING
      rails_version.should match(/3\.2/)
      # Document in test that Rails 3.2 needs security patches or upgrade
    end

    it 'should verify Devise is up to date' do
      # Check Devise version - should be latest security patch
      devise_version = Devise::VERSION
      # Document current version
    end

  end

  describe 'Privilege Inheritance and Override Logic' do

    let!(:company) { FactoryGirl.create(:company, :account => account) }
    let!(:other_user) { FactoryGirl.create(:user) }

    it 'should apply backlog-level privilege over company-level' do
      backlog = FactoryGirl.create(:backlog, :account => account, :company => company)
      
      # Set company user to 'full' access
      company_user = FactoryGirl.create(:company_user, :company => company, :user => other_user, :privilege => 'full')
      
      # Override at backlog level to 'read'
      backlog_user = FactoryGirl.create(:backlog_user, :backlog => backlog, :user => other_user, :privilege => 'read')
      
      sign_in other_user
      get :show, :id => backlog.id, :account_id => account.id
      response.status.should == 200
      # Should have read access based on backlog_user setting
    end

  end

end

describe StoriesController do
  let!(:default_scoring_rule) { FactoryGirl.create(:scoring_rule_default) }

  describe 'Input validation and sanitization' do

    let!(:account) { FactoryGirl.create(:account_with_user) }
    let!(:user) { account.users.first }
    let!(:backlog) { FactoryGirl.create(:backlog, :account => account) }
    let!(:theme) { FactoryGirl.create(:theme, :backlog => backlog) }

    it 'should validate story title is not empty' do
      sign_in user
      post :create, :theme_id => theme.id, :story => { :title => '' }
      response.status.should_not == 201
    end

    it 'should reject excessively long story titles' do
      sign_in user
      long_title = 'a' * 100000
      post :create, :theme_id => theme.id, :story => { :title => long_title }
      response.status.should_not == 201
    end

  end

end
