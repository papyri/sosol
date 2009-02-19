class WelcomeController < ApplicationController
  layout 'site'
  
  def index
    if @current_user
      render_component :controller => "articles", :action => "index"
    end
  end
end
