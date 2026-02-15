# Rake tasks for seeding sample data
# ==============================================================================
# Provides convenient tasks for loading demo/sample data into the database
# for learning and experimentation purposes.
# ==============================================================================

namespace :db do
  namespace :seed do
    desc "Load sample data for learning and experimentation (demo user, backlog, stories)"
    task :sample => :environment do
      load File.join(Rails.root, 'db', 'seeds_sample.rb')
    end
  end
end
