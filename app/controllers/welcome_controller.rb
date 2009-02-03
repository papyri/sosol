class WelcomeController < ApplicationController
  layout 'site'
  
  def index
    if @current_user
      @identifiers = @rpx.mappings(@current_user.id)
    end
  end
end
