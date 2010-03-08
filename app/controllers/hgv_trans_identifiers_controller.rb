class HgvTransIdentifiersController < IdentifiersController
  layout 'site'
  before_filter :authorize
  # require 'xml'
  # require 'xml/xslt'
  
  def edit
    find_identifier
		#raise "+" + @identifier.content

    # send xslt to page so it can use it on the fly
    f = File.open(File.join(RAILS_ROOT, 'data/xslt/translation/editable_preview.xsl'), "r")    
    @editable_preview_xsl = f.read    
    
    #send pn xslt to page so it can use it on the fly
    #pn_file = File.open(File.join(RAILS_ROOT, 'data/xslt/  
    #@xslt = XML::XSLT.file(File.join(RAILS_ROOT, 'data/xslt/start_edition.xsl'))
    #raise @xslt.to_s
    
    # pass glossary xml so page can find defs on the fly
    glossary_identifier = HGVTransGlossary.new({:publication => @identifier.publication})
    @glossary_xml = glossary_identifier.content
     
    #create glossary
    # xslt = XML::XSLT.new()
    # xslt.xml = REXML::Document.new @glossary_xml
    # xslt.xsl = REXML::Document.new File.open( File.join(RAILS_ROOT, 'data/xslt/translation/glossary_to_chooser.xsl'), "r")
    # @glossary = xslt.serve()
    
    @glossary = glossary_identifier.to_chooser
    
    #find text
    @identifier.publication.identifiers.each do |id|
      if (id.class.to_s == "DDBIdentifier")
        @identifier[:text_html_preview] = id.preview
      end    
    end
        
    #render :template => 'identifiers/editxml'
  end
  
  def update
    #raise "contents are: " + params[:content]
    find_identifier
    commit_sha = @identifier.set_content(params[:editing_trans_xml])
    
    if params[:comment] != nil && params[:comment].strip != ""
      @comment = Comment.new( {:git_hash => commit_sha, :user_id => @current_user.id, :identifier_id => @identifier.origin.id, :publication_id => @identifier.publication.origin.id, :comment => params[:comment], :reason => "commit" } )
      @comment.save    
    end
    
    flash[:notice] = "File updated."
    #@identifier.set_epidoc(params[:hgv_trans_identifier], params[:comment])
    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 :action => :edit)
  end
  
  # GET /publications/1/ddb_identifiers/1/preview
  def preview
    find_identifier
    
   # Dir.chdir(File.join(RAILS_ROOT, 'data/xslt/'))
   # xslt = XML::XSLT.new()
   # xslt.xml = REXML::Document.new(@identifier.xml_content)
   # xslt.xsl = REXML::Document.new File.open('start-divtrans-portlet.xsl')
    
   # @identifier[:html_preview] = xslt.serve()
    
    @identifier[:html_preview] = @identifier.preview
  end
  
  
  protected
    def find_identifier
      @identifier = HGVTransIdentifier.find(params[:id])
    end
end
