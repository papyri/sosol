class DdbIdentifiersController < ApplicationController
  layout 'site'
  
  # GET /publications/1/ddb_identifiers/edit
  def edit
    @publication = Publication.find(params[:publication_id])
    @identifier = DDBIdentifier.find(params[:id])
    @xml_content = @current_user.repository.get_file_from_branch(
      @identifier.to_path, @publication.branch)
  end
end