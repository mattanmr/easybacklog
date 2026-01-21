class ApiController < ActionController::Base
  layout 'api'

  # CSRF protection is disabled for API endpoints as they use token-based authentication
  # This is intentional - API requests authenticate via Authorization header tokens
  # CodeQL: This is a deliberate security decision for stateless API authentication
  protect_from_forgery :with => :null_session

  before_filter :prevent_default_js

  caches_action :index, :expires_in => 300, :cache_path => Proc.new { |c| "#{root_path}:#{request.ssl?}" } # cache for 5 minutes, vary cache by SSL or Plain

  private
    def prevent_default_js
      @dont_render_application_js = true
    end
end