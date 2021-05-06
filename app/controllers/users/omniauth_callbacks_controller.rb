class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    @user = User.from_omniauth(request.env['omniauth.auth'])

    if @user.persisted?
      flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: 'Google'
      sign_in_and_redirect @user, event: :authentication
    else
      session['devise.google_data'] = request.env['omniauth.auth'].except('extra') # Removing extra as it can overflow some session stores
      session[:identifier] = @user.user_identifiers.first.identifier
      Rails.logger.info("Session identifier: " + session[:identifier].inspect)
      Rails.logger.info("User from controller: " + @user.inspect)
      # We need to use render instead of redirect to pass parameters seamlessly
      if @user.errors.full_messages.present?
        render template: 'devise/registrations/new', alert: @user.errors.full_messages.join("\n")
      else
        render template: 'devise/registrations/new'
      end
    end
  end
end
