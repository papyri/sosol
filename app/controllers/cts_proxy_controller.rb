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
    if (CTS::CTSLib.get_subref(params[:urn]))
      redirect_to :action => :getsubref, :id => params[:id], :urn => params[:urn]
      return
    end
     render :xml => CTS::CTSLib.getPassage(params[:id],params[:urn],true)
  end
  
  def getsubref
    begin
      passage_text = CTS::CTSLib.get_tokenized_passage(params[:id],params[:urn])
      xslt_path = File.join(Rails.root,%w{data xslt cts passage_to_subref.xsl})
      if(params[:id] =~/^\d+$/)
        documentIdentifier = Identifier.find(params[:id])
        xslt_path = documentIdentifier.passage_subref_xslt_file
      end 
              
      render :text => JRubyXML.apply_xsl_transform(
        JRubyXML.stream_from_string(passage_text),
        JRubyXML.stream_from_file(File.join(Rails.root,%w{data xslt cts passage_to_subref.xsl})),
          :e_subref => CTS::CTSLib.get_subref(params[:urn]).to_s)
    rescue Exception => e
      Rails.logger.error(e.backtrace)
      render :text => e.to_s, :status => 500
    end
  end
    
  def getcapabilities
    if (params[:id] =~ /^\d+$/)  
      # get a json inventory object for the cts-enabled texts in the current publication                       
      publication = Publication.find(params[:id].to_s)
      has_inv = publication.identifiers.select { |i| i.respond_to?(:related_text_inventory) && (i.class != CitationCTSIdentifier) }
      if has_inv.size > 0
        render :json => JSON.generate(has_inv[0].related_text_inventory)
      else
        render :text => "Not Found", :status => 404
      end
   else
      response = CTS::CTSLib.proxyGetCapabilities(params[:id].to_s)
      render :json => JRubyXML.apply_xsl_transform(
                        JRubyXML.stream_from_string(response),
                        JRubyXML.stream_from_file(File.join(Rails.root,
                        %w{data xslt cts inventory_to_json.xsl})))    
    end
  end
  
 
 
  # get available repositories to search for annotation bodies 
  def getrepos
    repos = CTS::CTSLib.getExternalCTSRepos()

    if (params[:id])
       publication = Publication.find(params[:id].to_s)
       has_inv = publication.identifiers.select { |i| i.respond_to?(:related_text_inventory) && (i.class != CitationCTSIdentifier) }
       if (has_inv.size > 0) 
         urispace = root_url + "cts/getpassage"
         repos['keys'][params[:id]] = urispace
         repos['urispaces'][urispace] = params[:id]
       end
    end
    render :text => JSON.generate(repos) 
  end
  
end
