class HgvTransIdentifiersController < IdentifiersController
  layout 'site'
  before_filter :authorize
  
  def edit
    find_identifier

    # send xslt to page so it can use it on the fly
    f = File.open(File.join(RAILS_ROOT, 'data/xslt/translation/editable_preview.xsl'), "r")    
    @editable_preview_xsl = f.read      
    
    # pass glossary xml so page can find defs on the fly
    @glossary_xml = Glossary.new({:publication => @identifier.publication}).content
     
    #create glossary
    xslt = XML::XSLT.new()
    xslt.xml = REXML::Document.new @glossary_xml
    xslt.xsl = REXML::Document.new File.open( File.join(RAILS_ROOT, 'data/xslt/translation/glossary_to_chooser.xsl'), "r")    
    @glossary = xslt.serve()
        
    #render :template => 'identifiers/editxml'
  end
  
  def update
    find_identifier
    #@identifier.set_content(params[:editing_trans_xml])
    @identifier.set_epidoc(params[:hgv_trans_identifier], params[:comment])
    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 :action => :edit)
  end
  
  protected
    def find_identifier
      @identifier = HGVTransIdentifier.find(params[:id])
    end
end
