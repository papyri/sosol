class ApiClientsController < Doorkeeper::ApplicationsController
    before_filter :authorize
    before_filter :enforce_admin

    def authorize 
      @user = User.find_by_id(session[:user_id])
      if @user.nil?
        session[:entry_url] = request.fullpath
        redirect_to signin_url
      end
    end

    def enforce_admin
      unless @user.admin
        flash[:error] = "This action requires administrator rights"
        redirect_to :controller => "user", :action => "user_dashboard"
      end
    end

end
