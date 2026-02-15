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
    email: demo_email,
    password: 'password123',
    password_confirmation: 'password123',
    first_name: 'Demo',
    last_name: 'User',
    locale: Locale.find_by_code('en_US')
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
    locale: Locale.find_by_code('en_US')
  )
  
  # Link user to account
  AccountUser.create!(
    account: demo_account,
    user: demo_user,
    admin: true,
    privilege: AccountUser::PRIVILEGE_EDITOR
  )
  
  puts "✓ Created demo account: Demo Company"
end

# Create a sample backlog
# ==============================================================================
backlog = Backlog.find_by_name('Sample E-commerce Project')

if backlog
  puts "✓ Sample backlog already exists"
else
  backlog = Backlog.create!(
    account: demo_account,
    name: 'Sample E-commerce Project',
    velocity: 40,
    rate: 100.0,
    scoring_rule: ScoringRule.find_by_code(ScoringRule::FIBONACCI)
  )
  
  puts "✓ Created sample backlog: Sample E-commerce Project"
  
  # Create themes (high-level feature areas)
  # ==========================================================================
  themes = []
  
  themes << Theme.create!(
    backlog: backlog,
    name: 'User Authentication',
    code: 'AUTH',
    position: 1
  )
  
  themes << Theme.create!(
    backlog: backlog,
    name: 'Product Catalog',
    code: 'PROD',
    position: 2
  )
  
  themes << Theme.create!(
    backlog: backlog,
    name: 'Shopping Cart',
    code: 'CART',
    position: 3
  )
  
  themes << Theme.create!(
    backlog: backlog,
    name: 'Checkout & Payment',
    code: 'PAY',
    position: 4
  )
  
  puts "✓ Created #{themes.length} themes"
  
  # Create user stories
  # ==========================================================================
  stories = []
  
  # Authentication stories
  auth_theme = themes[0]
  
  stories << Story.create!(
    backlog: backlog,
    theme: auth_theme,
    unique_id: 'AUTH-1',
    as_a: 'Customer',
    i_want_to: 'create an account',
    so_i_can: 'save my information for future purchases',
    score_50: 3,
    score_90: 5,
    position: 1
  )
  
  stories << Story.create!(
    backlog: backlog,
    theme: auth_theme,
    unique_id: 'AUTH-2',
    as_a: 'Customer',
    i_want_to: 'log in to my account',
    so_i_can: 'access my order history and saved addresses',
    score_50: 2,
    score_90: 3,
    position: 2
  )
  
  stories << Story.create!(
    backlog: backlog,
    theme: auth_theme,
    unique_id: 'AUTH-3',
    as_a: 'Customer',
    i_want_to: 'reset my password',
    so_i_can: 'regain access if I forget it',
    score_50: 2,
    score_90: 3,
    position: 3
  )
  
  # Product catalog stories
  prod_theme = themes[1]
  
  stories << Story.create!(
    backlog: backlog,
    theme: prod_theme,
    unique_id: 'PROD-1',
    as_a: 'Customer',
    i_want_to: 'browse products by category',
    so_i_can: 'find items I am interested in',
    score_50: 5,
    score_90: 8,
    position: 4
  )
  
  stories << Story.create!(
    backlog: backlog,
    theme: prod_theme,
    unique_id: 'PROD-2',
    as_a: 'Customer',
    i_want_to: 'search for products by keyword',
    so_i_can: 'quickly find specific items',
    score_50: 5,
    score_90: 8,
    position: 5
  )
  
  stories << Story.create!(
    backlog: backlog,
    theme: prod_theme,
    unique_id: 'PROD-3',
    as_a: 'Customer',
    i_want_to: 'view product details and images',
    so_i_can: 'make informed purchase decisions',
    score_50: 3,
    score_90: 5,
    position: 6
  )
  
  stories << Story.create!(
    backlog: backlog,
    theme: prod_theme,
    unique_id: 'PROD-4',
    as_a: 'Customer',
    i_want_to: 'filter products by price and rating',
    so_i_can: 'find the best options within my budget',
    score_50: 3,
    score_90: 5,
    position: 7
  )
  
  # Shopping cart stories
  cart_theme = themes[2]
  
  stories << Story.create!(
    backlog: backlog,
    theme: cart_theme,
    unique_id: 'CART-1',
    as_a: 'Customer',
    i_want_to: 'add items to my cart',
    so_i_can: 'purchase multiple products at once',
    score_50: 3,
    score_90: 5,
    position: 8
  )
  
  stories << Story.create!(
    backlog: backlog,
    theme: cart_theme,
    unique_id: 'CART-2',
    as_a: 'Customer',
    i_want_to: 'update quantities in my cart',
    so_i_can: 'buy the right amount of each product',
    score_50: 2,
    score_90: 3,
    position: 9
  )
  
  stories << Story.create!(
    backlog: backlog,
    theme: cart_theme,
    unique_id: 'CART-3',
    as_a: 'Customer',
    i_want_to: 'remove items from my cart',
    so_i_can: 'change my mind about purchases',
    score_50: 1,
    score_90: 2,
    position: 10
  )
  
  stories << Story.create!(
    backlog: backlog,
    theme: cart_theme,
    unique_id: 'CART-4',
    as_a: 'Customer',
    i_want_to: 'see my cart total',
    so_i_can: 'know how much I will spend',
    score_50: 1,
    score_90: 2,
    position: 11
  )
  
  # Checkout stories
  pay_theme = themes[3]
  
  stories << Story.create!(
    backlog: backlog,
    theme: pay_theme,
    unique_id: 'PAY-1',
    as_a: 'Customer',
    i_want_to: 'enter my shipping address',
    so_i_can: 'receive my order',
    score_50: 3,
    score_90: 5,
    position: 12
  )
  
  stories << Story.create!(
    backlog: backlog,
    theme: pay_theme,
    unique_id: 'PAY-2',
    as_a: 'Customer',
    i_want_to: 'select a shipping method',
    so_i_can: 'choose between speed and cost',
    score_50: 2,
    score_90: 3,
    position: 13
  )
  
  stories << Story.create!(
    backlog: backlog,
    theme: pay_theme,
    unique_id: 'PAY-3',
    as_a: 'Customer',
    i_want_to: 'pay securely with my credit card',
    so_i_can: 'complete my purchase',
    score_50: 8,
    score_90: 13,
    position: 14
  )
  
  stories << Story.create!(
    backlog: backlog,
    theme: pay_theme,
    unique_id: 'PAY-4',
    as_a: 'Customer',
    i_want_to: 'receive an order confirmation email',
    so_i_can: 'have a record of my purchase',
    score_50: 2,
    score_90: 3,
    position: 15
  )
  
  puts "✓ Created #{stories.length} user stories"
  
  # Create a sprint with some stories
  # ==========================================================================
  sprint = Sprint.create!(
    backlog: backlog,
    name: 'Sprint 1 - MVP',
    number_team_members: 3,
    duration_days: 14,
    position: 1
  )
  
  # Add first 5 stories to sprint
  stories[0..4].each_with_index do |story, index|
    SprintStory.create!(
      sprint: sprint,
      story: story,
      sprint_story_status: SprintStoryStatus.find_by_code(
        index < 2 ? SprintStoryStatus::COMPLETED : SprintStoryStatus::IN_PROGRESS
      ),
      position: index + 1
    )
  end
  
  puts "✓ Created sprint with 5 stories"
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
puts "The demo account includes:"
puts "  • 1 sample backlog (E-commerce Project)"
puts "  • 4 themes (Authentication, Products, Cart, Payment)"
puts "  • 15 user stories with realistic point estimates"
puts "  • 1 active sprint with 5 stories"
puts ""
puts "🎉 Happy exploring!"
