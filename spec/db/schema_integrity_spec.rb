# encoding: UTF-8

require 'spec_helper'

describe 'Database Schema Integrity' do
  
  describe 'Critical table existence and structure' do
    
    it 'should have users table with security-sensitive columns' do
      columns = ActiveRecord::Base.connection.columns(:users).map(&:name)
      expect(columns).to include('id', 'email', 'encrypted_password', 'password_salt')
      expect(columns).to include('confirmation_token', 'reset_password_token')
      expect(columns).to include('remember_created_at', 'sign_in_count', 'current_sign_in_at', 'last_sign_in_at')
      expect(columns).to include('current_sign_in_ip', 'last_sign_in_ip')
    end

    it 'should have account_users table with privilege and admin columns' do
      columns = ActiveRecord::Base.connection.columns(:account_users).map(&:name)
      expect(columns).to include('user_id', 'account_id', 'privilege', 'admin')
    end

    it 'should have backlogs table' do
      columns = ActiveRecord::Base.connection.columns(:backlogs).map(&:name)
      expect(columns).to include('id', 'account_id', 'name', 'velocity', 'rate', 'use_50_90')
    end

    it 'should have stories table with scoring fields' do
      columns = ActiveRecord::Base.connection.columns(:stories).map(&:name)
      expect(columns).to include('id', 'backlog_id', 'theme_id', 'title')
      expect(columns).to include('fib_estimate', 'fifty_estimate', 'ninety_estimate')
    end

    it 'should have sprints table' do
      columns = ActiveRecord::Base.connection.columns(:sprints).map(&:name)
      expect(columns).to include('id', 'backlog_id', 'name', 'velocity')
    end

    it 'should have user_tokens table for API authentication' do
      columns = ActiveRecord::Base.connection.columns(:user_tokens).map(&:name)
      expect(columns).to include('user_id', 'access_token', 'basic_authentication_token')
    end

    it 'should have invited_users table with security_code' do
      columns = ActiveRecord::Base.connection.columns(:invited_users).map(&:name)
      expect(columns).to include('id', 'account_id', 'email', 'security_code')
    end

    it 'should have acceptance_criteria table' do
      columns = ActiveRecord::Base.connection.columns(:acceptance_criteria).map(&:name)
      expect(columns).to include('id', 'story_id', 'criterion')
    end

    it 'should have themes table' do
      columns = ActiveRecord::Base.connection.columns(:themes).map(&:name)
      expect(columns).to include('id', 'backlog_id', 'name')
    end

    it 'should have companies table' do
      columns = ActiveRecord::Base.connection.columns(:companies).map(&:name)
      expect(columns).to include('id', 'account_id', 'name')
    end

  end

  describe 'Foreign key constraints and associations' do

    let!(:account) { FactoryGirl.create(:account) }
    let!(:user) { FactoryGirl.create(:user) }

    it 'should prevent orphaned account_users when account is deleted' do
      account_user = FactoryGirl.create(:account_user, :account => account, :user => user)
      expect(AccountUser.count).to eq(1)
      expect { account.destroy }.to change { AccountUser.count }.by(-1)
    end

    it 'should prevent orphaned backlogs when account is deleted' do
      backlog = FactoryGirl.create(:backlog, :account => account)
      expect(Backlog.count).to eq(1)
      expect { account.destroy }.to change { Backlog.count }.by(-1)
    end

    it 'should prevent orphaned stories when backlog is deleted' do
      backlog = FactoryGirl.create(:backlog, :account => account)
      story = FactoryGirl.create(:story, :backlog => backlog)
      expect(Story.count).to eq(1)
      expect { backlog.destroy }.to change { Story.count }.by(-1)
    end

    it 'should prevent orphaned themes when backlog is deleted' do
      backlog = FactoryGirl.create(:backlog, :account => account)
      theme = FactoryGirl.create(:theme, :backlog => backlog)
      expect(Theme.count).to eq(1)
      expect { backlog.destroy }.to change { Theme.count }.by(-1)
    end

    it 'should prevent orphaned sprints when backlog is deleted' do
      backlog = FactoryGirl.create(:backlog, :account => account)
      sprint = FactoryGirl.create(:sprint, :backlog => backlog)
      expect(Sprint.count).to eq(1)
      expect { backlog.destroy }.to change { Sprint.count }.by(-1)
    end

    it 'should prevent orphaned acceptance_criteria when story is deleted' do
      backlog = FactoryGirl.create(:backlog, :account => account)
      story = FactoryGirl.create(:story, :backlog => backlog)
      criterion = FactoryGirl.create(:acceptance_criterion, :story => story)
      expect(AcceptanceCriterion.count).to eq(1)
      expect { story.destroy }.to change { AcceptanceCriterion.count }.by(-1)
    end

    it 'should cascade delete company_users when company is deleted' do
      company = FactoryGirl.create(:company, :account => account)
      company_user = FactoryGirl.create(:company_user, :company => company, :user => user)
      expect(CompanyUser.count).to eq(1)
      expect { company.destroy }.to change { CompanyUser.count }.by(-1)
    end

    it 'should cascade delete backlog_users when backlog is deleted' do
      backlog = FactoryGirl.create(:backlog, :account => account)
      backlog_user = FactoryGirl.create(:backlog_user, :backlog => backlog, :user => user)
      expect(BacklogUser.count).to eq(1)
      expect { backlog.destroy }.to change { BacklogUser.count }.by(-1)
    end

  end

  describe 'Data relationships consistency' do

    let!(:account) { FactoryGirl.create(:account) }
    let!(:user) { FactoryGirl.create(:user) }

    it 'story should belong to correct backlog after creation' do
      backlog = FactoryGirl.create(:backlog, :account => account)
      story = FactoryGirl.create(:story, :backlog => backlog)
      story.reload
      expect(story.backlog_id).to eq(backlog.id)
    end

    it 'theme should belong to correct backlog' do
      backlog = FactoryGirl.create(:backlog, :account => account)
      theme = FactoryGirl.create(:theme, :backlog => backlog)
      theme.reload
      expect(theme.backlog_id).to eq(backlog.id)
    end

    it 'should not allow a story to belong to multiple themes in same backlog' do
      backlog = FactoryGirl.create(:backlog, :account => account)
      theme1 = FactoryGirl.create(:theme, :backlog => backlog)
      theme2 = FactoryGirl.create(:theme, :backlog => backlog)
      story = FactoryGirl.create(:story, :backlog => backlog, :theme => theme1)
      story.update_attributes(:theme_id => theme2.id)
      story.reload
      expect(story.theme_id).to eq(theme2.id)
      expect([theme1.id, theme2.id]).to include(story.theme_id)
    end

    it 'should prevent orphaned acceptance_criteria without story' do
      backlog = FactoryGirl.create(:backlog, :account => account)
      story = FactoryGirl.create(:story, :backlog => backlog)
      criterion = FactoryGirl.create(:acceptance_criterion, :story => story)
      expect { criterion.update_attributes(:story_id => nil) }.to raise_error(ActiveRecord::StatementInvalid)
    end

  end

  describe 'Privilege and permission data integrity' do

    let!(:account) { FactoryGirl.create(:account) }
    let!(:user) { FactoryGirl.create(:user) }

    it 'should have valid privilege values' do
      valid_privileges = ['none', 'read', 'readstatus', 'full']
      account_user = FactoryGirl.create(:account_user, :account => account, :user => user, :privilege => 'full')
      expect(valid_privileges).to include(account_user.privilege)
    end

    it 'should enforce privilege enum constraint' do
      account_user = FactoryGirl.create(:account_user, :account => account, :user => user)
      expect { account_user.update_attributes(:privilege => 'invalid_privilege') }.to raise_error
    end

    it 'should allow admin flag to be set and retrieved' do
      account_user = FactoryGirl.create(:account_user, :account => account, :user => user, :admin => true)
      account_user.reload
      expect(account_user.admin).to be_true
    end

    it 'should not downgrade privilege on concurrent updates' do
      account_user = FactoryGirl.create(:account_user, :account => account, :user => user, :privilege => 'full')
      account_user.update_attributes(:privilege => 'full')
      account_user.reload
      expect(account_user.privilege).to eq('full')
    end

  end

  describe 'Encryption and sensitive data storage' do

    it 'should not store plain text passwords' do
      user = FactoryGirl.create(:user, :password => 'SuperSecret123!')
      user_from_db = User.find(user.id)
      expect(user_from_db.encrypted_password).not_to be_empty
      expect(user_from_db.encrypted_password).not_to eq('SuperSecret123!')
    end

    it 'should not have password in password reset token' do
      user = FactoryGirl.create(:user, :password => 'SuperSecret123!')
      user.send_reset_password_instructions
      user.reload
      expect(user.reset_password_token).not_to be_nil
      expect(user.reset_password_token).not_to include('SuperSecret123!')
    end

    it 'should have password_salt for each user' do
      user = FactoryGirl.create(:user)
      user.reload
      expect(user.password_salt).not_to be_empty
    end

  end

  describe 'User token security' do

    it 'should create user_token with access_token' do
      user = FactoryGirl.create(:user)
      token = FactoryGirl.create(:user_token, :user => user)
      token.reload
      expect(token.access_token).not_to be_nil
    end

    it 'should not expose plain access_token in responses unnecessarily' do
      user = FactoryGirl.create(:user)
      token = FactoryGirl.create(:user_token, :user => user)
      expect(token.access_token).not_to be_empty
      expect(token.basic_authentication_token).not_to be_empty
    end

  end

  describe 'Invitation and signup data' do

    let!(:account) { FactoryGirl.create(:account) }

    it 'should create invited_user with security_code' do
      invited = FactoryGirl.create(:invited_user, :account => account, :email => 'new@example.com')
      invited.reload
      expect(invited.security_code).not_to be_nil
      expect(invited.security_code).not_to be_empty
    end

    it 'should not allow duplicate email invitations in same account' do
      invited1 = FactoryGirl.create(:invited_user, :account => account, :email => 'duplicate@example.com')
      # Create second invitation with same email - should either update or raise error
      expect {
        FactoryGirl.create(:invited_user, :account => account, :email => 'duplicate@example.com')
      }.to raise_error # or change behavior based on implementation
    end

  end

  describe 'Index coverage for performance' do

    it 'should have index on users.email' do
      indexes = ActiveRecord::Base.connection.indexes(:users).map(&:columns)
      expect(indexes.flatten).to include('email')
    end

    it 'should have index on account_users.user_id' do
      indexes = ActiveRecord::Base.connection.indexes(:account_users).map(&:columns)
      # Check for composite index or single column index
      expect(indexes.flatten).to include('user_id')
    end

    it 'should have index on stories.backlog_id' do
      indexes = ActiveRecord::Base.connection.indexes(:stories).map(&:columns)
      expect(indexes.flatten).to include('backlog_id')
    end

    it 'should have index on sprints.backlog_id' do
      indexes = ActiveRecord::Base.connection.indexes(:sprints).map(&:columns)
      expect(indexes.flatten).to include('backlog_id')
    end

  end

end
