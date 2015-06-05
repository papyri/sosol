# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'ad8f219816db8990ae5254e6c8ea4b25'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password
  
  # Pick a unique cookie name to distinguish our session data from others'
  # this is set in environment.rb
  # session :session_key => '_sosol_session_id'
  # layout 'default'

  include MaintenanceMode
  before_filter :disabled?

  before_filter :get_user_id
  before_filter :rpx_setup

  before_filter :tab_setup

  before_filter :accept_terms , :except => [:terms, :update_terms]

  unless ActionController::Base.consider_all_requests_local
    rescue_from Exception, :with => :render_500
    rescue_from ActionController::RoutingError, :with => :render_404
    rescue_from ActionController::UnknownAction, :with => :render_404
    rescue_from ActiveRecord::RecordNotFound, :with => :render_404
    rescue_from NumbersRDF::Timeout, :with => :render_numbers_error
  end

  layout SITE_LAYOUT
  
  protected

  def render_500(e)
    notify_airbrake(e)
    @redirect = true unless request.referer =~ /dashboard$/
    flash[:error] = "We're sorry, but something went wrong."
    @additional_error_information = "We've been notified about this issue and we'll take a look at it shortly."
    render :template => 'common/error_500', :layout => false, :status => 500
  end

  def render_numbers_error(e)
    notify_airbrake(e)
    @redirect = false
    flash.now[:error] = "We're sorry, but the Numbers Server appears to be unresponsive."
    @additional_error_information = "Please contact this site's administrator."
    render :template => 'common/error_500', :layout => false, :status => 500
  end

  def render_404(e)
    flash[:error] = "The page you were looking for doesn't exist."
    render :template => 'common/error_404', :layout => false, :status => 404
  end
  
  def authorize
    if @current_user.nil?
      session[:entry_url] = request.url
      flash[:notice] = "Please log in"
      redirect_to signin_url
    end
  end

  private
  
  def get_user_id  
    if (ENV['RAILS_ENV'] == "test") && !params[:test_user_id].blank?

      @current_user = User.find_by_id params[:test_user_id].to_s
      session[:user_id] == params[:test_user_id].to_s

      return true
    end
  
    user_id = session[:user_id]
    if user_id
      @current_user = User.find_by_id user_id
    end
    return true
  end
  
  def rpx_setup
    unless Object.const_defined?(:RPX_API_KEY) && Object.const_defined?(:RPX_BASE_URL) && Object.const_defined?(:RPX_REALM)
      render :template => 'const_message'
      return false
    end
    @rpx = Rpx::RpxHelper.new(RPX_API_KEY, RPX_BASE_URL, RPX_REALM)
    return true
  end
  
  
  def tab_setup
    @current_board = nil
    @currrent_identifier = nil
    
  end

  # make sure the current user has already accepted
  # the terms of service
  def accept_terms
    unless @current_user.nil?
      if @current_user.accepted_terms?
        return true
      else
        redirect_to :controller => :user, :action => :terms
        return
      end
    else
      return true
    end
  end
  
end
