class HgvTransIdentifiersController < IdentifiersController
  layout 'site'
  before_filter :authorize
  require 'xml'
  require 'xml/xslt'
  
  def edit
    find_identifier

    #send xslt to page so it can use it on the fly
    f = File.open(File.join(RAILS_ROOT, 'data/xslt/translation/editable_preview.xsl'), "r")    
    @editable_preview_xsl = f.read    
    
    #send pn xslt to page so it can use it on the fly
    #pn_file = File.open(File.join(RAILS_ROOT, 'data/xslt/  
    #@xslt = XML::XSLT.file(File.join(RAILS_ROOT, 'data/xslt/start_edition.xsl'))
    #raise @xslt.to_s
    
    #create glossary
    xslt = XML::XSLT.new()
    xslt.xml = REXML::Document.new File.open(File.join(RAILS_ROOT, 'data/xslt/translation/hgv-glossary.xml'), "r")
    xslt.xsl = REXML::Document.new File.open( File.join(RAILS_ROOT, 'data/xslt/translation/glossary_to_chooser.xsl'), "r")    
    @glossary = xslt.serve()
    
    #pass glossary xml so page can find defs on the fly
    gloss = File.open(File.join(RAILS_ROOT, 'data/xslt/translation/hgv-glossary.xml'), "r")
    @glossary_xml = gloss.read
    
    #render :template => 'identifiers/editxml'
  end
  
  def update
    find_identifier
    #@identifier.set_content(params[:editing_trans_xml])
    @identifier.set_epidoc(params[:hgv_trans_identifier], params[:comment])
    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 :action => :edit)
  end
  
  # GET /publications/1/ddb_identifiers/1/preview
  def preview
    find_identifier
    
    Dir.chdir(File.join(RAILS_ROOT, 'data/xslt/'))
    xslt = XML::XSLT.new()
    xslt.xml = REXML::Document.new(@identifier.xml_content)
    xslt.xsl = REXML::Document.new File.open('start-divtrans-portlet.xsl')
    
    @identifier[:html_preview] = xslt.serve()
  end
  
  
  protected
    def find_identifier
      @identifier = HGVTransIdentifier.find(params[:id])
    end
end
