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

  before_filter :get_user_id
  before_filter :rpx_setup

  private

  def get_user_id
    user_id = session[:user_id]
    if user_id
      @current_user = User.find_by_id user_id
    end
    return true
  end

  def rpx_setup
    unless Object.const_defined?(:API_KEY) && Object.const_defined?(:BASE_URL) && Object.const_defined?(:REALM)
      render :template => 'const_message'
      return false
    end
    @rpx = Rpx::RpxHelper.new(API_KEY, BASE_URL, REALM)
    return true
  end
end
