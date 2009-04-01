class UserController < ApplicationController
  layout 'site'
  
  def signout
    reset_session
    redirect_to :controller => :welcome, :action => "index"
  end
  
  def account
    if @current_user
      @identifiers = @rpx.mappings(@current_user.id)
    end
  end
  
  def signin
    
  end
  
  def index  	  
  	if @current_user.admin
  		@users = User.find(:all)
  	else
  	  render :file => 'public/403.html', :status => '403'
  	end
  end
  
  def ask_language_prefs
    @langs = @current_user.language_prefs
  
  end

  def set_language_prefs
    @current_user.language_prefs =  params[:languages]
    @current_user.save
    
    redirect_to :controller => :user, :action => "dashboard"
  end  
  
  def dashboard
    #don't let someone who isn't signed in go to the dashboard
    if @current_user == nil
      redirect_to :controller => "user", :action => "signin"
    end
	
  end
end
