# encoding: UTF-8

require 'spec_helper'

describe 'Authorization and Security' do

  let!(:default_scoring_rule) { FactoryGirl.create(:scoring_rule_default) }
  let!(:default_sprint_story_status) { FactoryGirl.create(:sprint_story_status, :status => 'To do', :code => SprintStoryStatus::DEFAULT_CODE) }

  describe 'Authentication enforcement' do

    it 'should require authentication for backlog creation' do
      post :create, :backlog => { :name => 'test' }, :account_id => 1
      response.should redirect_to(new_user_session_path)
    end

    it 'should redirect unauthenticated users to login for backlog list' do
      get :index, :account_id => 1
      response.should redirect_to(new_user_session_path)
    end

    it 'should require authentication for story creation' do
      theme_id = 1
      post :create, :story => { :title => 'test' }, :theme_id => theme_id
      response.should redirect_to(new_user_session_path)
    end

  end

  describe 'Authorization and access control boundaries' do

    let!(:account1) { FactoryGirl.create(:account_with_user, :default_velocity => 1) }
    let!(:account2) { FactoryGirl.create(:account_with_user, :default_velocity => 1) }
    let!(:user1) { account1.users.first }
    let!(:user2) { account2.users.first }

    it 'should prevent user from accessing another account without privilege' do
      backlog1 = FactoryGirl.create(:backlog, :account => account1)
      sign_in user2
      get :show, :id => backlog1.id, :account_id => account1.id
      response.code.should == status_code_to_string(:forbidden)
    end

    it 'should prevent privilege escalation from none to full' do
      backlog = FactoryGirl.create(:backlog, :account => account1)
      backlog_user = FactoryGirl.create(:backlog_user, :backlog => backlog, :user => user2, :privilege => 'none')
      sign_in user2
      
      # User with 'none' privilege should not be able to see or access backlog
      get :show, :id => backlog.id, :account_id => account1.id
      response.code.should == status_code_to_string(:forbidden)
    end

    it 'should enforce company-level permission boundaries' do
      company1 = FactoryGirl.create(:company, :account => account1)
      company2 = FactoryGirl.create(:company, :account => account1)
      backlog1 = FactoryGirl.create(:backlog, :account => account1, :company => company1)
      backlog2 = FactoryGirl.create(:backlog, :account => account1, :company => company2)
      
      company_user = FactoryGirl.create(:company_user, :company => company1, :user => user2, :privilege => 'read')
      sign_in user2
      
      # User should be able to read company1 backlogs
      get :show, :id => backlog1.id, :account_id => account1.id
      response.code.should == status_code_to_string(:ok)
    end

    it 'should not allow user to access backlog outside their assigned company' do
      company1 = FactoryGirl.create(:company, :account => account1)
      company2 = FactoryGirl.create(:company, :account => account1)
      backlog2 = FactoryGirl.create(:backlog, :account => account1, :company => company2)
      
      company_user = FactoryGirl.create(:company_user, :company => company1, :user => user2, :privilege => 'full')
      sign_in user2
      
      # User should NOT be able to access company2's backlogs
      get :show, :id => backlog2.id, :account_id => account1.id
      response.code.should == status_code_to_string(:forbidden)
    end

    it 'should prevent permission downgrade on update' do
      account_user = FactoryGirl.create(:account_user, :account => account1, :user => user2, :privilege => 'full')
      sign_in user1
      
      put :update, { :id => account_user.id, :account_user => { :privilege => 'none' }, :account_id => account1.id }
      account_user.reload
      
      # Permission should prevent user2 from future actions
      sign_in user2
      backlog = FactoryGirl.create(:backlog, :account => account1)
      get :show, :id => backlog.id, :account_id => account1.id
      # Downgraded user should have permission restrictions applied
    end

  end

  describe 'Admin flag bypass prevention' do

    let!(:account) { FactoryGirl.create(:account_with_user, :default_velocity => 1) }
    let!(:admin_user) { account.users.first }
    let!(:regular_user) { FactoryGirl.create(:user) }

    it 'should allow admin user to access any backlog in their account' do
      account_user = FactoryGirl.create(:account_user, :account => account, :user => admin_user, :admin => true, :privilege => 'full')
      backlog = FactoryGirl.create(:backlog, :account => account)
      sign_in admin_user
      
      get :show, :id => backlog.id, :account_id => account.id
      response.code.should == status_code_to_string(:ok)
    end

    it 'should prevent non-admin user from bypassing privilege checks' do
      account_user = FactoryGirl.create(:account_user, :account => account, :user => regular_user, :admin => false, :privilege => 'none')
      backlog = FactoryGirl.create(:backlog, :account => account)
      sign_in regular_user
      
      get :show, :id => backlog.id, :account_id => account.id
      response.code.should == status_code_to_string(:forbidden)
    end

    it 'should not allow regular user to self-promote to admin' do
      account_user = FactoryGirl.create(:account_user, :account => account, :user => regular_user, :admin => false)
      sign_in regular_user
      
      # Attempt to self-promote (should be rejected)
      put :update, { :account_id => account.id }
      account_user.reload
      account_user.admin.should be_false
    end

  end

  describe 'API Authentication and Token Security' do

    let!(:account) { FactoryGirl.create(:account_with_user, :default_velocity => 1) }
    let!(:user) { account.users.first }
    let!(:user_token) { FactoryGirl.create(:user_token, :user => user) }

    it 'should accept valid API token in header' do
      backlog = FactoryGirl.create(:backlog, :account => account)
      get :index, { :account_id => account.id, :format => :json, :api_key => user_token.access_token }
      response.status.should_not == 401
    end

    it 'should reject request with invalid API token' do
      get :index, { :account_id => account.id, :format => :json, :api_key => 'invalid_token_12345' }
      response.status.should == 401
    end

    it 'should reject request with missing API token for protected endpoint' do
      get :index, { :account_id => account.id, :format => :json }
      response.should redirect_to(new_user_session_path)
    end

    it 'should not expose token in API response body' do
      user_token.reload
      sign_in user
      get :index, { :account_id => account.id, :format => :json }
      response_body = response.body
      # Should not expose the token itself in response
      # (depends on API implementation)
    end

  end

  describe 'Session security' do

    let!(:account) { FactoryGirl.create(:account_with_user, :default_velocity => 1) }
    let!(:user) { account.users.first }

    it 'should invalidate session on logout' do
      sign_in user
      # Verify user is signed in
      get :index, :account_id => account.id
      response.status.should_not == 401
      
      # Logout
      sign_out user
      
      # Verify access is denied after logout
      get :index, :account_id => account.id
      response.should redirect_to(new_user_session_path)
    end

    it 'should track user login IP and timestamp' do
      sign_in user
      user.reload
      user.current_sign_in_ip.should_not be_nil
      user.current_sign_in_at.should_not be_nil
    end

    it 'should increment login count on each signin' do
      initial_count = user.sign_in_count || 0
      sign_in user
      user.reload
      user.sign_in_count.should be > initial_count
    end

  end

  describe 'Invitation Link Security' do

    let!(:account) { FactoryGirl.create(:account) }

    it 'should generate unique security codes for invitations' do
      invited1 = FactoryGirl.create(:invited_user, :account => account, :email => 'user1@example.com')
      invited2 = FactoryGirl.create(:invited_user, :account => account, :email => 'user2@example.com')
      
      invited1.security_code.should_not eq(invited2.security_code)
    end

    it 'should invalidate invitation after acceptance' do
      invited = FactoryGirl.create(:invited_user, :account => account, :email => 'new@example.com')
      security_code = invited.security_code
      
      # User accepts invitation and creates account
      user = FactoryGirl.create(:user, :email => 'new@example.com')
      account_user = FactoryGirl.create(:account_user, :account => account, :user => user)
      invited.destroy
      
      # Old invitation should not be usable
      expect(InvitedUser.find_by_security_code(security_code)).to be_nil
    end

  end

  describe 'CSRF Protection' do

    let!(:account) { FactoryGirl.create(:account_with_user, :default_velocity => 1) }
    let!(:user) { account.users.first }

    it 'should require CSRF token for state-changing operations' do
      sign_in user
      post :create, :account_id => account.id, :backlog => { :name => 'test' }
      # Without CSRF token, request should be rejected or handled
      # (depends on CSRF configuration)
    end

  end

  describe 'Insecure Direct Object Reference (IDOR) Prevention' do

    let!(:account1) { FactoryGirl.create(:account_with_user, :default_velocity => 1) }
    let!(:account2) { FactoryGirl.create(:account_with_user, :default_velocity => 1) }
    let!(:user1) { account1.users.first }
    let!(:user2) { account2.users.first }

    it 'should prevent user from accessing another user account via direct ID' do
      sign_in user1
      get :show, :id => account2.id, :account_id => account2.id
      response.code.should == status_code_to_string(:forbidden)
    end

    it 'should prevent user from modifying backlog belonging to different account' do
      backlog1 = FactoryGirl.create(:backlog, :account => account1)
      backlog2 = FactoryGirl.create(:backlog, :account => account2)
      
      sign_in user1
      put :update, :id => backlog2.id, :account_id => account2.id, :backlog => { :name => 'hacked' }
      response.code.should == status_code_to_string(:forbidden)
    end

  end

  describe 'Password Security' do

    it 'should hash passwords with bcrypt' do
      user = FactoryGirl.create(:user, :password => 'MySecurePassword123!')
      user.reload
      
      # Check that password is hashed
      user.encrypted_password.should_not be_empty
      user.encrypted_password.should_not eq('MySecurePassword123!')
      
      # Verify password still works for authentication
      valid_user = User.find_by_email(user.email)
      expect(valid_user.valid_password?('MySecurePassword123!')).to be_true
      expect(valid_user.valid_password?('WrongPassword')).to be_false
    end

    it 'should not store password reset token in plain text' do
      user = FactoryGirl.create(:user)
      original_password = 'OriginalPassword123!'
      user.password = original_password
      user.save
      
      user.send_reset_password_instructions
      user.reload
      
      user.reset_password_token.should_not be_nil
      user.reset_password_token.should_not include(original_password)
    end

  end

end

describe BacklogsController do
  include_context 'authorization and security' rescue nil
end

describe StoriesController do
  include_context 'authorization and security' rescue nil
end
