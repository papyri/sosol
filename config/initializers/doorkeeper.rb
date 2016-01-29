Doorkeeper.configure do
  default_scopes :read
  optional_scopes :write

  #force_ssl_in_redirect_uri !Rails.env.development?
  force_ssl_in_redirect_uri !Rails.env.development?

  resource_owner_authenticator do
    @user = User.find_by_id(session[:user_id])
    unless @user 
      session[:entry_url] = request.fullpath
      redirect_to(signin_url)
    end
    @user
  end
end
