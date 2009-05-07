class DdbIdentifiersController < ApplicationController
  layout 'site'
  
  # GET /publications/1/ddb_identifiers/1/edit
  def edit
    editxml
    @identifier[:leiden_plus] = @identifier.leiden_plus
  end
  
  # GET /publications/1/ddb_identifiers/1/editxml
  def editxml
    find_identifier
    @identifier[:xml_content] = @identifier.xml_content
  end
  
  # PUT /publications/1/ddb_identifiers/1/update
  def update
    find_identifier
    # transform back to XML
    xml_content = @identifier.leiden_plus_to_xml(
      params[:ddb_identifier][:leiden_plus])
    # commit xml to repo
    @identifier.set_xml_content(xml_content,
                                params[:comment])
    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 :action => :edit)
  end
  
  # PUT /publications/1/ddb_identifiers/1/updatexml
  def updatexml
    find_identifier
    # strip carriage returns
    xml_content = params[:ddb_identifier][:xml_content].gsub(/\r\n?/, "\n")
    @identifier.set_xml_content(xml_content,
                                params[:comment])
    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 :action => :editxml)
  end
  
  # GET /publications/1/ddb_identifiers/1/history
  def history
    find_identifier
    @identifier[:commits] = 
      @identifier.publication.user.repository.get_log_for_file_from_branch(
        @identifier.to_path, @identifier.publication.branch
    )
  end
  
  # GET /publications/1/ddb_identifiers/1/preview
  def preview
    editxml
    
    Dir.chdir(File.join(RAILS_ROOT, 'data/xslt/'))
    xslt = XML::XSLT.new()
    xslt.xml = REXML::Document.new(@identifier[:xml_content])
    xslt.xsl = REXML::Document.new File.open('start-div-portlet.xsl')
    
    @identifier[:html_preview] = xslt.serve()
  end
  
  protected
    def find_identifier
      @identifier = DDBIdentifier.find(params[:id])
    end
  
    def find_publication_and_identifier
      @publication = Publication.find(params[:publication_id])
      find_identifier
    end
end