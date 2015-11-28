Doorkeeper.configure do
  resource_owner_authenticator do
    @user = User.find_by_id(session[:user_id])
    Rails.logger.info("Session details #{session.inspect}")
    unless @user 
      session[:entry_url] = request.fullpath
      Rails.logger.info("Why aren't we being redirected to #{session[:return_to]}")
      redirect_to(signin_url)
    end
    @user
  end
end
