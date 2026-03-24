# Rake tasks for seeding sample data
# ==============================================================================

namespace :db do
  namespace :seed do
    desc "Load sample data (demo user, backlog, stories)"
    task :sample => :environment do
      load File.join(Rails.root, 'db', 'seeds_sample.rb')
    end
  end
end
