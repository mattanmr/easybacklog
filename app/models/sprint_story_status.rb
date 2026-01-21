class SprintStoryStatus < ActiveRecord::Base
  ACCEPTED = 'D' # was done
  DEFAULT_CODE = 'T' # default to to do
  IN_PROGRESS = 'P'
  COMPLETED = 'R' # completed / ready for testing

  has_many :sprint_stories, :inverse_of => :sprint_story_status

  acts_as_list

  validates_presence_of :status, :code
  validates_uniqueness_of :status, :code

  # Mass assignment protection - no attributes accessible by default
  # This is a system-managed model (sprint story statuses are configured by admins)
  # If you need to make attributes mass-assignable, add them here:
  # attr_accessible :status, :code, :position
  attr_accessible

  def self.accepted
    find_by_code(ACCEPTED)
  end
end