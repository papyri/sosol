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
    # strip carriage returns
    xml_content = params[:xml_content][:to_s].gsub(/\r\n?/, "\n")
    @identifier.set_xml_content(@publication,
                                xml_content,
                                params[:comment])
    redirect_to edit_polymorphic_path([@publication, @identifier])
  end
  
  # GET /publications/1/ddb_identifiers/1/history
  def history
    @publication = Publication.find(params[:publication_id])
    @identifier = DDBIdentifier.find(params[:id])
    @commits = @publication.user.repository.get_log_for_file_from_branch(
      @identifier.to_path, @publication.branch
    )
  end
end