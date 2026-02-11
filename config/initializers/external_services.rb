# External Services Configuration
# 
# This initializer controls whether external services are enabled.
# Set ENABLE_EXTERNAL_SERVICES=true in your environment to re-enable all external services.
#
# External services controlled by this flag:
# - SendGrid SMTP email delivery
# - Google Analytics tracking
# - UserEcho feedback widget
# - Ably real-time API
# - Exceptional error tracking
# - New Relic performance monitoring

module ExternalServices
  # Check if external services should be enabled
  # Default: false (disabled) for local development
  # Override: Set ENV['ENABLE_EXTERNAL_SERVICES'] = 'true' to enable
  def self.enabled?
    ENV['ENABLE_EXTERNAL_SERVICES'] == 'true'
  end

  # Individual service flags (can be overridden separately)
  def self.email_enabled?
    ENV['ENABLE_EMAIL'] == 'true' || enabled?
  end

  def self.analytics_enabled?
    ENV['ENABLE_ANALYTICS'] == 'true' || enabled?
  end

  def self.feedback_enabled?
    ENV['ENABLE_FEEDBACK'] == 'true' || enabled?
  end

  def self.realtime_enabled?
    ENV['ENABLE_REALTIME'] == 'true' || enabled?
  end

  def self.error_tracking_enabled?
    ENV['ENABLE_ERROR_TRACKING'] == 'true' || enabled?
  end

  def self.performance_monitoring_enabled?
    ENV['ENABLE_PERFORMANCE_MONITORING'] == 'true' || enabled?
  end
end

# Log the status at startup
if Rails.env.development?
  puts "\n" + "="*80
  puts "EXTERNAL SERVICES STATUS"
  puts "="*80
  puts "Email Delivery:          #{ExternalServices.email_enabled? ? 'ENABLED' : 'DISABLED'}"
  puts "Analytics:               #{ExternalServices.analytics_enabled? ? 'ENABLED' : 'DISABLED'}"
  puts "Feedback Widget:         #{ExternalServices.feedback_enabled? ? 'ENABLED' : 'DISABLED'}"
  puts "Real-time API:           #{ExternalServices.realtime_enabled? ? 'ENABLED' : 'DISABLED'}"
  puts "Error Tracking:          #{ExternalServices.error_tracking_enabled? ? 'ENABLED' : 'DISABLED'}"
  puts "Performance Monitoring:  #{ExternalServices.performance_monitoring_enabled? ? 'ENABLED' : 'DISABLED'}"
  puts "="*80
  puts "To enable all services: Set ENABLE_EXTERNAL_SERVICES=true in your environment"
  puts "To enable individual services: Set ENABLE_<SERVICE>=true"
  puts "="*80 + "\n\n"
end
