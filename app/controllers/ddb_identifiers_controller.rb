class DdbIdentifiersController < ApplicationController
  layout 'site'
  
  # GET /publications/1/ddb_identifiers/1/edit
  def edit
    editxml
    @leiden_plus = @identifier.leiden_plus
  end
  
  # GET /publications/1/ddb_identifiers/1/editxml
  def editxml
    find_publication_and_identifier
    @xml_content = @identifier.xml_content
  end
  
  # PUT /publications/1/ddb_identifiers/1/update
  def update
    find_publication_and_identifier
    # transform back to XML
    xml_content = @identifier.leiden_plus_to_xml(params[:leiden_plus])
    # commit xml to repo
    @identifier.set_xml_content(xml_content,
                                params[:comment])
    redirect_to polymorphic_path([@publication, @identifier],
                                 :action => :edit)
  end
  
  # PUT /publications/1/ddb_identifiers/1/updatexml
  def updatexml
    find_publication_and_identifier
    # strip carriage returns
    xml_content = params[:xml_content].gsub(/\r\n?/, "\n")
    @identifier.set_xml_content(xml_content,
                                params[:comment])
    redirect_to polymorphic_path([@publication, @identifier],
                                 :action => :editxml)
  end
  
  # GET /publications/1/ddb_identifiers/1/history
  def history
    find_publication_and_identifier
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
  
  protected
  
    def find_publication_and_identifier
      @publication = Publication.find(params[:publication_id])
      @identifier = DDBIdentifier.find(params[:id])
    end
end