class CollectionIdentifiersController < ApplicationController
  before_filter :authorize
  before_filter :check_admin

  #Ensures user has admin rights to view page. Otherwise returns 403 error.
  def check_admin
    if @current_user.nil? || !@current_user.admin
      render :file => 'public/403.html', :status => '403'
    end
  end

  def update
  end

  def update_review
  end
end
