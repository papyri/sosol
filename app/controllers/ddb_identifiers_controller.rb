class DdbIdentifiersController < IdentifiersController
  layout 'site'
  before_filter :authorize
  
  # GET /publications/1/ddb_identifiers/1/edit
  def edit
    find_identifier
    @identifier[:leiden_plus] = @identifier.leiden_plus
  end
  
  # PUT /publications/1/ddb_identifiers/1/update
  def update
    find_identifier
    @identifier.set_leiden_plus(params[:ddb_identifier][:leiden_plus],
                                params[:comment])
    flash[:notice] = "File updated."
    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 :action => :edit)
  end
  
  # GET /publications/1/ddb_identifiers/1/preview
  def preview
    find_identifier
    
    # Dir.chdir(File.join(RAILS_ROOT, 'data/xslt/'))
    # xslt = XML::XSLT.new()
    # xslt.xml = REXML::Document.new(@identifier.xml_content)
    # xslt.xsl = REXML::Document.new File.open('start-div-portlet.xsl')
    # xslt.serve()
    
    java.lang.System.setProperty("javax.xml.transform.TransformerFactory", "net.sf.saxon.TransformerFactoryImpl")
    transformer_factory = javax.xml.transform.TransformerFactory.newInstance()
    transformer = transformer_factory.newTransformer(javax.xml.transform.stream.StreamSource.new(File.join(RAILS_ROOT, 'data', 'xslt', 'start-div-portlet.xsl')))
    
    string_writer = java.io.StringWriter.new()
    result = javax.xml.transform.stream.StreamResult.new(string_writer)
    xml_source = javax.xml.transform.stream.StreamSource.new(
      java.io.StringReader.new(@identifier.xml_content))
    
    transformer.transform(xml_source, result)
    
    @identifier[:html_preview] = string_writer.toString()
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
