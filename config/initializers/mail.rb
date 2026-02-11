# if using foreman, then send using SMTP as part of the worker queue
# Mail delivery is disabled by default for local development
# To enable: Set ENABLE_EMAIL=true or ENABLE_EXTERNAL_SERVICES=true in your environment
if Rails.env.test? || !ExternalServices.email_enabled?
  puts ">> Mail will not be delivered (external services disabled)"
  puts ">> To enable email: Set ENABLE_EMAIL=true in your environment"
else
  puts ">> Mail delivery ENABLED via SendGrid"
  ActionMailer::Base.smtp_settings = {
    :address        => 'smtp.sendgrid.net',
    :port           => '587',
    :authentication => :plain,
    :user_name      => ENV['SENDGRID_USERNAME'],
    :password       => ENV['SENDGRID_PASSWORD'],
    :domain         => 'easybacklog.com'
  }
  ActionMailer::Base.delivery_method = :smtp
end
