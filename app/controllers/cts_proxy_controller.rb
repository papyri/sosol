class CtsProxyController < ApplicationController
  def editions
    response = CTS::CTSLib.getEditionUrns(params[:inventory].to_s)
    render plain: response
  end

  def validreffs
    @publication = Publication.find(params[:publication_id].to_s)
    inventory = new_identifier.related_inventory
    response = CTS::CTSLib.proxyGetValidReff(inventory, params[:urn].to_s, params[:level].to_s)
    render plain: response
  end

  def translations
    response = CTS::CTSLib.getTranslationUrns(params[:inventory].to_s, params[:urn].to_s)
    render plain: response
  end

  def citations
    response = CTS::CTSLib.getCitationLabels(params[:inventory].to_s, params[:urn].to_s)
    render plain: response
  end

  def getpassage
    if params[:id] =~ /^\d+$/
      documentIdentifier = Identifier.find(params[:id].to_s)
      inventory_code = documentIdentifier.related_inventory.name.split('/')[0]
      if CTS::CTSLib.getExternalCTSHash.key?(inventory_code)
        response = CTS::CTSLib.proxyGetPassage(inventory_code, params[:urn].to_s)
      else
        inventory = documentIdentifier.related_inventory.xml_content
        uuid = "#{documentIdentifier.publication.id}#{params[:urn].gsub(':', '_')}_proxyreq"
        response = CTS::CTSLib.getPassageFromRepo(inventory, documentIdentifier.content, params[:urn].to_s, uuid)
      end
    else
      response = CTS::CTSLib.proxyGetPassage(params[:id].to_s, params[:urn].to_s)
    end
    render plain: JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(response),
      JRubyXML.stream_from_file(File.join(Rails.root,
                                          %w[data xslt cts extract_text.xsl]))
    )
  end

  def getcapabilities
    response = CTS::CTSLib.proxyGetCapabilities(params[:collection].to_s)
    render plain: JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(response),
      JRubyXML.stream_from_file(File.join(Rails.root,
                                          %w[data xslt cts inventory_to_json.xsl]))
    )
  end

  def getrepos
    render plain: CTS::CTSLib.getExternalCTSReposAsJson
  end
end
