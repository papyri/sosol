class CtsProxyController < ApplicationController

  def editions
    response = CTS::CTSLib.getEditionUrns(params[:inventory].to_s)
    render :text => response
  end
  
  def validreffs
    @publication = Publication.find(params[:publication_id].to_s)
    inventory = new_identifier.related_inventory
    response = CTS::CTSLib.proxyGetValidReff(inventory, params[:urn].to_s, params[:level].to_s)
    render :text => response
  end
  
  def translations
    response = CTS::CTSLib.getTranslationUrns(params[:inventory].to_s,params[:urn].to_s)
    render :text => response
  end
  
  def citations
    response = CTS::CTSLib.getCitationLabels(params[:inventory].to_s,params[:urn].to_s)
    render :text => response
  end
  
  def getpassage
    if (params[:id] =~ /^\d+$/)
      documentIdentifier = Identifier.find(params[:id].to_s)
      inventory_code = documentIdentifier.related_inventory.name.split('/')[0]
      if (CTS::CTSLib.getExternalCTSHash().has_key?(inventory_code))
        response = CTS::CTSLib.proxyGetPassage(inventory_code,params[:urn].to_s)
      else
        inventory = documentIdentifier.related_inventory.xml_content
        uuid = documentIdentifier.publication.id.to_s + params[:urn].gsub(':','_') + '_proxyreq'
        response = CTS::CTSLib.getPassageFromRepo(inventory,documentIdentifier.content,params[:urn].to_s,uuid)
     end
    else
      response = CTS::CTSLib.proxyGetPassage(params[:id].to_s,params[:urn].to_s)
    end
    render :xml => response
  end
    
  def getcapabilities
    if (params[:id] =~ /^\d+$/)  
      # get a json inventory object for the cts-enabled texts in the current publication                       
      identifier = Identifier.find(params[:id].to_s)
      render :text => JSON.generate(identifier.related_text_inventory)
   else
      response = CTS::CTSLib.proxyGetCapabilities(params[:id].to_s)
      render :text => JRubyXML.apply_xsl_transform(
                        JRubyXML.stream_from_string(response),
                        JRubyXML.stream_from_file(File.join(RAILS_ROOT,
                        %w{data xslt cts inventory_to_json.xsl})))    
    end
  end
  
 
 
  # get available repositories to search for annotation bodies 
  def getrepos
    repos = CTS::CTSLib.getExternalCTSRepos()

    if (params[:id])
       identifier = Identifier.find(params[:id].to_s)
       related = identifier.related_text_inventory
       related.keys.each do |key|
         urispace = root_url + "/dmm_api/" + identifier.class.to_s + "/" + params[:id]
         repos['keys'][key.to_s] = urispace
         repos['urispaces'][urispace] = key.to_s
       end
    end
    render :text => JSON.generate(repos) 
  end
  
end
