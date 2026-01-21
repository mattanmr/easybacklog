class CronLog < ActiveRecord::Base
  # Mass assignment protection - system-managed model
  attr_accessible

  def self.cleanup
    CronLog.where('created_at < ?', Time.now - 21.days).delete_all
  end
end