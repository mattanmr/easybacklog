# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

# Create default locales if they don't exist
[
  { :name => 'English (United States)', :code => 'en_US' },
  { :name => 'English (United Kingdom)', :code => 'en_GB' },
  { :name => 'German', :code => 'de_DE' },
  { :name => 'French', :code => 'fr_FR' },
  { :name => 'Spanish', :code => 'es_ES' },
  { :name => 'Italian', :code => 'it_IT' }
].each_with_index do |locale_data, index|
  Locale.create(locale_data.merge(:position => index + 1)) unless Locale.find_by_code(locale_data[:code])
end

# Ensure sprint story statuses exist (required during sample backlog creation)
[
  { :status => 'To do', :code => SprintStoryStatus::DEFAULT_CODE },
  { :status => 'In progress', :code => SprintStoryStatus::IN_PROGRESS },
  { :status => 'Completed', :code => SprintStoryStatus::COMPLETED },
  { :status => 'Accepted', :code => SprintStoryStatus::ACCEPTED }
].each_with_index do |status_data, index|
  SprintStoryStatus.find_or_create_by_code(status_data[:code]) do |record|
    record.status = status_data[:status]
    record.position = index + 1
  end
end
