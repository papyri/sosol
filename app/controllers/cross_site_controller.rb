class CrossSiteController < ApplicationController
  
  def sign_in_out
    render :partial => "/common/sign_in_out" 
  end
  
  def advanced_create
    render :partial => "/common/advanced_create"
  end
end