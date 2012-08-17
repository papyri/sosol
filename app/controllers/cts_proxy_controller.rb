class CtsProxyController < ApplicationController

  def editions
    response = CTS::CTSLib.getEditionUrns(params[:inventory])
    render :text => response
  end
  
  def validreffs
    @publication = Publication.find(params[:publication_id])
    inventory = new_identifier.related_inventory
    response = CTS::CTSLib.proxyGetValidReff(inventory, params[:urn], params[:level])
    render :text => response
  end
  
  def translations
    response = CTS::CTSLib.getTranslationUrns(params[:inventory],params[:urn])
    render :text => response
  end
  
  def citations
    response = CTS::CTSLib.getCitationLabels(params[:inventory],params[:urn])
    render :text => response
  end

end
