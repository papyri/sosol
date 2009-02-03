class UserController < ApplicationController
  def logout
    reset_session
    redirect_to :controller => :welcome, :action => "index"
  end
  
  def login
    
  end
end
