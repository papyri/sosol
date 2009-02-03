class WelcomeController < ApplicationController
  def index
    if @current_user
      @identifiers = @rpx.mappings(@current_user.id)
    end
  end
  
  def logout
    reset_session
    redirect_to :action => "index"
  end
end
