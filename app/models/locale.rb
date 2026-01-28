class Locale < ActiveRecord::Base
  has_many :accounts, :inverse_of => :locale

  validates_presence_of :name, :code

  # Mass assignment protection - system-managed model
  attr_accessible
end