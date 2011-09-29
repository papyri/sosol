class CrossSiteController < ApplicationController
  
  def sign_in_out
    render :partial => "sign_in_out" 
  end
  
  def advanced_create
    render :partial => "advanced_create"
  end

  def header
    render :partial => "header"
  end
  
  def footer
    render :partial => "footer"
  end
  
  

  
end