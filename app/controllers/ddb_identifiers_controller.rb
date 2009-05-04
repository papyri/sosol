class DdbIdentifiersController < ApplicationController
  layout 'site'
  
  # GET /publications/1/ddb_identifiers/1/edit
  def edit
    @publication = Publication.find(params[:publication_id])
    @identifier = DDBIdentifier.find(params[:id])
    @xml_content = @identifier.xml_content(@publication)
  end
  
  # PUT /publications/1/ddb_identifiers/1/update
  def update
    @publication = Publication.find(params[:publication_id])
    @identifier = DDBIdentifier.find(params[:id])
    @identifier.set_xml_content(@publication, params[:xml_content][:to_s], "dummy comment")
  end
end