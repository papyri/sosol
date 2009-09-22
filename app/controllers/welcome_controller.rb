class WelcomeController < ApplicationController
  layout 'site'
  
  def index
    if @current_user
      render_component :controller => "user", :action => "dashboard"
    end
  end
end
