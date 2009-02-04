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
end
