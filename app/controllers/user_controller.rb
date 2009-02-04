class UserController < ApplicationController
  layout 'site'
  
  def signout
    reset_session
    redirect_to :controller => :welcome, :action => "index"
  end
  
  def signin
    
  end
end
