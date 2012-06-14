class CtsProxyController < ApplicationController

  def editions
    response = CTS::CTSLib.getEditionUrns(params[:inventory])
    render :text => response
  end
  
  def validreffs
    response = CTS::CTSLib.proxyGetValidReff(params[:inventory], params[:urn], params[:level])
    render :text => response
  end
  
  def translations
    response = CTS::CTSLib.getTranslationUrns(params[:inventory],params[:urn])
    render :text => response
  end
end
