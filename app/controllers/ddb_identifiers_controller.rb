class DdbIdentifiersController < ApplicationController
  layout 'site'
  
  # GET /publications/1/ddb_identifiers/1/edit
  def edit
    editxml
    @leiden_plus = @identifier.leiden_plus(@publication)
  end
  
  # GET /publications/1/ddb_identifiers/1/editxml
  def editxml
    @publication = Publication.find(params[:publication_id])
    @identifier = DDBIdentifier.find(params[:id])
    @xml_content = @identifier.xml_content(@publication)
  end
  
  # PUT /publications/1/ddb_identifiers/1/update
  def update
    @publication = Publication.find(params[:publication_id])
    @identifier = DDBIdentifier.find(params[:id])
    # strip carriage returns
    xml_content = params[:xml_content].gsub(/\r\n?/, "\n")
    @identifier.set_xml_content(@publication,
                                xml_content,
                                params[:comment])
    redirect_to polymorphic_path([@publication, @identifier],
                                 :action => :editxml)
  end
  
  # GET /publications/1/ddb_identifiers/1/history
  def history
    @publication = Publication.find(params[:publication_id])
    @identifier = DDBIdentifier.find(params[:id])
    @commits = @publication.user.repository.get_log_for_file_from_branch(
      @identifier.to_path, @publication.branch
    )
  end
  
  # GET /publications/1/ddb_identifiers/1/preview
  def preview
    editxml
    
    Dir.chdir(File.join(RAILS_ROOT, 'data/xslt/'))
    xslt = XML::XSLT.new()
    xslt.xml = REXML::Document.new(@xml_content)
    xslt.xsl = REXML::Document.new File.open('start-div-portlet.xsl')
    
    @transformed = xslt.serve()
  end
end