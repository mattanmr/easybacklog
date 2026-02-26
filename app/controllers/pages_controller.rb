class PagesController < ApplicationController
  basic_allowed :contact, :browser_support
  before_filter :authenticate_user!, :only => [:home]

  # routed as dashboard
  def home
    if current_user.accounts.length > 1
      # show activity across all accounts
      @recent_backlogs = current_user.accounts.map { |accounts| accounts.backlogs.active.where_user_has_access(current_user) }
      # show most recent first
      @recent_backlogs = @recent_backlogs.flatten.sort_by(&:updated_at).reverse[0..15]
      # group by company/account
      @recent_backlogs = @recent_backlogs.group_by { |backlog| backlog.company.present? ? backlog.company : backlog.account }
    else
      flash.keep
      redirect_to logged_in_user_home_path
    end
  end

  def realtime_token
    # Real-time features disabled by default for local development
    # To enable: Set ENABLE_REALTIME=true or ENABLE_EXTERNAL_SERVICES=true
    unless ExternalServices.realtime_enabled?
      return render status: :service_unavailable, json: { 
        error: "Real-time features are disabled. Set ENABLE_REALTIME=true to enable." 
      }
    end

    raise "Ably API key is missing, set env var ABLY_API_KEY" unless ENV['ABLY_API_KEY']
    unless current_user
      return render status: :unauthorized, json: { error: "A realtime token cannot be issued unless you are logged in, please log in first" }
    end

    ably = Ably::Rest.new(key: ENV['ABLY_API_KEY'])
    render json: ably.auth.create_token_request(client_id: current_user.id.to_s)
  end

  def contact
    # Auto-renders: app/views/pages/contact.html.haml
  end

  def faq
    # Auto-renders: app/views/pages/faq.html.haml
  end
end
