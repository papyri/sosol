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
  
  def ask_language_prefs
    @langs = @current_user.language_prefs
  
  end

  def set_language_prefs
    @current_user.language_prefs =  params[:languages]
    @current_user.save
    
    redirect_to :controller => :user, :action => "dashboard"
  end  
  
  def dashboard
	
  end
end
