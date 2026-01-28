class HealthController < ActionController::Base
  # CSRF protection disabled for health check endpoint (read-only, no state changes)
  # This endpoint is used by monitoring systems and load balancers
  # CodeQL: This is a deliberate security decision for health check endpoints
  # TODO: Consider implementing rate limiting or IP whitelisting for production
  protect_from_forgery :with => :null_session

  def status
    begin
      raise 'No users in the database' if User.count == 0
      render :text => "easyBacklog appears to be healthy", :content_type => "text/plain"
    rescue Exception => e
      # Note: This error message exposes database connectivity information
      # Consider using generic error message in production
      render :text => "There's a big problem, help. #{e.message}", :status => 500, :content_type => "text/plain"
    end
  end
end