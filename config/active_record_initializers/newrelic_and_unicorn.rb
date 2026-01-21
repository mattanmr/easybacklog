# Ensure the agent is started using Unicorn
# This is needed when using Unicorn and preload_app is not set to true.
# See http://support.newrelic.com/kb/troubleshooting/unicorn-no-data
# 
# Performance monitoring disabled by default for local development
# To enable: Set ENABLE_PERFORMANCE_MONITORING=true or ENABLE_EXTERNAL_SERVICES=true
if defined?(Unicorn)
  if defined?(ExternalServices) && ExternalServices.performance_monitoring_enabled?
    ::NewRelic::Agent.after_fork(:force_reconnect => true)
  elsif ENV['ENABLE_PERFORMANCE_MONITORING'] == 'true' || ENV['ENABLE_EXTERNAL_SERVICES'] == 'true'
    ::NewRelic::Agent.after_fork(:force_reconnect => true)
  end
end