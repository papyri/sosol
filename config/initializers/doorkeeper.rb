Doorkeeper.configure do
  default_scopes :public
  optional_scopes :write, :read

  resource_owner_authenticator do
    @user = User.find_by_id(session[:user_id])
    unless @user 
      session[:entry_url] = request.fullpath
      redirect_to(signin_url)
    end
    @user
  end
end
