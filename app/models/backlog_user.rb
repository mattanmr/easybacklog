class BacklogUser < ActiveRecord::Base
  belongs_to :user, :inverse_of => :backlog_users
  belongs_to :backlog, :inverse_of => :backlog_users
  validates_presence_of :user_id, :backlog_id

  include PrivilegeProperty

  # Mass assignment protection - privilege code is managed via PrivilegeProperty
  attr_accessible :privilege

  def admin?
    backlog.account.account_users.find_by_user_id(user_id).admin?
  end
end