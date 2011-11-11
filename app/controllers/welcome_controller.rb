class WelcomeController < ApplicationController
  ##layout 'site'
  
  def index
    if @current_user
      redirect_to :controller => "user", :action => "dashboard"
      return
    end
  end
end
