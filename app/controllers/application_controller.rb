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

  # include ::MaintenanceMode
  # before_action :disabled?

  before_action :get_user_id
  before_action :rpx_setup

  before_action :tab_setup

  before_action :configure_permitted_parameters, if: :devise_controller?

  unless Rails.application.config.consider_all_requests_local
    rescue_from Exception, with: :render_500
    rescue_from ActionController::RoutingError, with: :render_404
    rescue_from AbstractController::ActionNotFound, with: :render_404
    rescue_from ActiveRecord::RecordNotFound, with: :render_404
    rescue_from NumbersRDF::Timeout, with: :render_numbers_error
  end

  layout Sosol::Application.config.site_layout

  def after_sign_in_path_for(_resource)
    dashboard_path
  end

  def after_sign_up_path_for(_resource)
    dashboard_path
  end

  protected

  def render_500(e)
    Rails.logger.debug(e.inspect)
    notify_airbrake(e)
    @redirect = true unless /dashboard$/.match?(request.referer)
    flash[:error] = "We're sorry, but something went wrong."
    @additional_error_information = "We've been notified about this issue and we'll take a look at it shortly."
    render template: 'common/error_500', layout: false, status: :internal_server_error
  end

  def render_numbers_error(e)
    Rails.logger.debug(e.inspect)
    notify_airbrake(e)
    @redirect = false
    flash.now[:error] = "We're sorry, but the Numbers Server appears to be unresponsive."
    @additional_error_information = "Please contact this site's administrator."
    render template: 'common/error_500', layout: false, status: :internal_server_error
  end

  def render_404(e)
    Rails.logger.debug(e.inspect)
    flash[:error] = "The page you were looking for doesn't exist."
    render template: 'common/error_404', layout: false, status: :not_found
  end

  def authorize
    if @current_user.nil?
      session[:entry_url] = request.url
      flash[:notice] = 'Please log in'
      redirect_to signin_url
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up,
                                      keys: %i[name full_name affiliation email password password_confirmation
                                               remember_me])
    devise_parameter_sanitizer.permit(:sign_in, keys: %i[login password remember_me])
    devise_parameter_sanitizer.permit(:account_update,
                                      keys: %i[full_name affiliation email password password_confirmation
                                               current_password])
  end

  private

  def get_user_id
    if (ENV['RAILS_ENV'] == 'test') && params[:test_user_id].present?

      @current_user = User.find_by id: params[:test_user_id].to_s
      session[:user_id] == params[:test_user_id].to_s

      return true
    end

    user_id = session[:user_id]
    @current_user = User.find_by id: user_id if user_id
    @current_user = current_user if current_user.present? && @current_user.blank?
    true
  end

  def rpx_setup
    if Rails.env.test? && !defined?(Sosol::Application.config.rpx_api_key) && !defined?(Sosol::Application.config.rpx_realm)
      @rpx = Rpx::RpxHelper.new('', Sosol::Application.config.rpx_base_url, '')
      return true
    elsif Sosol::Application.config.rpx_api_key.nil? || Sosol::Application.config.rpx_base_url.nil? || Sosol::Application.config.rpx_realm.nil?
      render template: 'const_message'
      return false
    end
    @rpx = Rpx::RpxHelper.new(Sosol::Application.config.rpx_api_key, Sosol::Application.config.rpx_base_url,
                              Sosol::Application.config.rpx_realm)
    true
  end

  def tab_setup
    @current_board = nil
    @currrent_identifier = nil
  end
end
