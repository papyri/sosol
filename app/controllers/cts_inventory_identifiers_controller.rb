# frozen_string_literal: true

class CtsInventoryIdentifiersController < IdentifiersController
  layout Sosol::Application.config.site_layout
  before_action :authorize

  # GET /publications/1/epi_cts_identifiers/1/preview
  def preview
    find_identifier

    # Dir.chdir(File.join(Rails.root, 'data/xslt/'))
    # xslt = XML::XSLT.new()
    # xslt.xml = REXML::Document.new(@identifier.xml_content)
    # xslt.xsl = REXML::Document.new File.open('start-div-portlet.xsl')
    # xslt.serve()

    @identifier_html_preview = @identifier.preview
  end

  protected

  def find_identifier
    @identifier = CTSInventoryIdentifier.find(params[:id].to_s)
  end

  def find_publication_and_identifier
    @publication = Publication.find(params[:publication_id].to_s)
    find_identifier
  end
end
