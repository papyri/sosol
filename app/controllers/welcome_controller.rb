class WelcomeController < ApplicationController
  ##layout 'site'
  
  def index
    if @current_user
      redirect_to :controller => "user", :action => "dashboard"
      return
    end
    render SiteHelper::is_perseids? ? 'welcome_perseids' : 'welcome'
  end
end
