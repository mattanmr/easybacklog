# Sample Data Seed for Learning and Experimentation
# ==============================================================================
# This file creates sample data to help students explore easyBacklog's features.
# Run this after db:seed to populate the database with example data:
#
#   docker compose exec web bundle exec rake db:seed:sample
#
# Or in Rails console:
#   load 'db/seeds_sample.rb'
# ==============================================================================

puts "🌱 Creating sample data for easyBacklog..."

# First ensure basic data exists
unless Locale.exists?
  puts "⚠️  Base data not found. Please run 'rake db:seed' first."
  exit
end

# Create a demo user
# ==============================================================================
demo_email = 'demo@example.com'
demo_user = User.find_by_email(demo_email)

if demo_user
  puts "✓ Demo user already exists: #{demo_email}"
else
  demo_user = User.create!(
    name: 'Demo User',
    email: demo_email,
    password: 'password123',
    password_confirmation: 'password123'
  )
  puts "✓ Created demo user: #{demo_email} (password: password123)"
end

# Create a demo account (organization)
# ==============================================================================
demo_account = Account.find_by_name('Demo Company')

if demo_account
  puts "✓ Demo account already exists: Demo Company"
else
  demo_account = Account.create!(
    name: 'Demo Company',
    locale_id: Locale.find_by_code('en_US').id,
    default_velocity: 40,
    default_rate: 100
  )
  
  # Link user to account
  AccountUser.create!(
    account: demo_account,
    user: demo_user,
    admin: true,
    privilege: 'full'  # full access privilege
  )
  
  puts "✓ Created demo account: Demo Company"
end

# Create a sample backlog
# ==============================================================================
backlog = Backlog.find_by_name('Sample E-commerce Project')

if backlog
  puts "✓ Sample backlog already exists"
else
  backlog = Backlog.new(
    account: demo_account,
    name: 'Sample E-commerce Project',
    velocity: 40,
    rate: 100.0,
    scoring_rule_id: ScoringRule.find_by_code(ScoringRule::FIBONACCI).id
  )
  backlog.author_id = demo_user.id
  backlog.last_modified_user_id = demo_user.id
  backlog.save!
  
  puts "✓ Created sample backlog: Sample E-commerce Project"
  
  # Create themes (high-level feature areas)
  # ==========================================================================
  themes = []
  
  theme1 = Theme.new(
    name: 'User Authentication',
    code: 'AUT',  # Must be exactly 3 characters
    position: 1
  )
  theme1.backlog_id = backlog.id
  theme1.save!
  themes << theme1
  
  theme2 = Theme.new(
    name: 'Product Catalog',
    code: 'PRD',
    position: 2
  )
  theme2.backlog_id = backlog.id
  theme2.save!
  themes << theme2
  
  theme3 = Theme.new(
    name: 'Shopping Cart',
    code: 'CRT',
    position: 3
  )
  theme3.backlog_id = backlog.id
  theme3.save!
  themes << theme3
  
  theme4 = Theme.new(
    name: 'Checkout & Payment',
    code: 'PAY',
    position: 4
  )
  theme4.backlog_id = backlog.id
  theme4.save!
  themes << theme4
  
  puts "✓ Created #{themes.length} themes"
  
  # Create user stories
  # ==========================================================================
  # Helper method to create stories properly
  def create_story(backlog, theme, attrs)
    story = Story.new(attrs.except(:backlog, :theme))
    story.backlog_id = backlog.id
    story.theme_id = theme.id
    story.save!
    story
  end
  
  stories = []
  
  # Authentication stories
  auth_theme = themes[0]
  
  stories << create_story(backlog, auth_theme, {
    unique_id: 'AUT-1',
    as_a: 'Customer',
    i_want_to: 'create an account',
    so_i_can: 'save my information for future purchases',
    score_50: 3,
    score_90: 5,
    position: 1
  })
  
  stories << create_story(backlog, auth_theme, {
    unique_id: 'AUT-2',
    as_a: 'Customer',
    i_want_to: 'log in to my account',
    so_i_can: 'access my order history and saved addresses',
    score_50: 2,
    score_90: 3,
    position: 2
  })
  
  # Product catalog stories
  prod_theme = themes[1]
  
  stories << create_story(backlog, prod_theme, {
    unique_id: 'PRD-1',
    as_a: 'Customer',
    i_want_to: 'browse products by category',
    so_i_can: 'find items I am interested in',
    score_50: 5,
    score_90: 8,
    position: 3
  })
  
  stories << create_story(backlog, prod_theme, {
    unique_id: 'PRD-2',
    as_a: 'Customer',
    i_want_to: 'search for products by keyword',
    so_i_can: 'quickly find specific items',
    score_50: 5,
    score_90: 8,
    position: 4
  })
  
  # Shopping cart stories
  cart_theme = themes[2]
  
  stories << create_story(backlog, cart_theme, {
    unique_id: 'CRT-1',
    as_a: 'Customer',
    i_want_to: 'add items to my cart',
    so_i_can: 'purchase multiple products at once',
    score_50: 3,
    score_90: 5,
    position: 5
  })
  
  stories << create_story(backlog, cart_theme, {
    unique_id: 'CRT-2',
    as_a: 'Customer',
    i_want_to: 'update quantities in my cart',
    so_i_can: 'buy the right amount of each product',
    score_50: 2,
    score_90: 3,
    position: 6
  })
  
  # Checkout stories
  pay_theme = themes[3]
  
  stories << create_story(backlog, pay_theme, {
    unique_id: 'PAY-1',
    as_a: 'Customer',
    i_want_to: 'enter my shipping address',
    so_i_can: 'receive my order',
    score_50: 3,
    score_90: 5,
    position: 7
  })
  
  stories << create_story(backlog, pay_theme, {
    unique_id: 'PAY-2',
    as_a: 'Customer',
    i_want_to: 'pay securely with my credit card',
    so_i_can: 'complete my purchase',
    score_50: 8,
    score_90: 13,
    position: 8
  })
  
  puts "✓ Created #{stories.length} user stories"
  
  # Create a sprint with some stories
  # ==========================================================================
  sprint = Sprint.new(
    number_team_members: 3,
    duration_days: 14
  )
  sprint.backlog_id = backlog.id
  sprint.name = 'Sprint 1 - MVP'
  sprint.position = 1
  sprint.save!
  
  # Add first 3 stories to sprint
  [0, 1, 2].each do |index|
    story = stories[index]
    sprint_story = SprintStory.new(
      position: index + 1
    )
    sprint_story.sprint_id = sprint.id
    sprint_story.story_id = story.id
    sprint_story.sprint_story_status_id = SprintStoryStatus.find_by_code(
      index < 1 ? SprintStoryStatus::COMPLETED : SprintStoryStatus::IN_PROGRESS
    ).id
    sprint_story.save!
  end
  
  puts "✓ Created sprint with 3 stories"
end

# Summary
# ==============================================================================
puts ""
puts "✅ Sample data creation complete!"
puts ""
puts "You can now log in with:"
puts "  Email:    demo@example.com"
puts "  Password: password123"
puts ""
puts ""
puts "The demo account includes:"
puts "  • 1 sample backlog (E-commerce Project)"
puts "  • 4 themes (Authentication, Products, Cart, Payment)"
puts "  • 8 user stories with realistic point estimates"
puts "  • 1 active sprint with 3 stories"
puts ""
puts "🎉 Happy exploring!"
