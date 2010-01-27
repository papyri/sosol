class DdbIdentifiersController < IdentifiersController
  layout 'site'
  before_filter :authorize
  
  # GET /publications/1/ddb_identifiers/1/edit
  def edit
    find_identifier
    begin
      @identifier[:leiden_plus] = @identifier.leiden_plus
    rescue RXSugar::XMLParseError => parse_error
      flash[:error] = "Error at line #{parse_error.line}, column #{parse_error.column}"
      @identifier[:leiden_plus] = parse_error.content
    end
  end
  
  # PUT /publications/1/ddb_identifiers/1/update
  def update
    find_identifier
    @identifier.set_leiden_plus(params[:ddb_identifier][:leiden_plus],
                                params[:comment])
    if params[:comment] != nil && params[:comment].strip != ""
      @comment = Comment.new( {:git_hash => "todo", :user_id => @current_user.id, :identifier_id => @identifier.origin.id, :publication_id => @identifier.publication.origin.id, :comment => params[:comment], :reason => "commit" } )
      @comment.save
    end
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

    @identifier[:html_preview] = @identifier.preview
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
