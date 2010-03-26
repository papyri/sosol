class DdbIdentifiersController < IdentifiersController
  layout 'site'
  before_filter :authorize
  
  # GET /publications/1/ddb_identifiers/1/edit
  def edit
    find_identifier
    begin
      @identifier[:leiden_plus] = @identifier.leiden_plus
    rescue RXSugar::XMLParseError => parse_error
      flash.now[:error] = "Error parsing XML at line #{parse_error.line}, column #{parse_error.column}"
      @identifier[:leiden_plus] = parse_error.content
    end
  end
  
  # PUT /publications/1/ddb_identifiers/1/update
  def update
    find_identifier
    @bad_leiden = false
    @original_commit_comment = ''
    if params[:commit] == "Save With Broken Leiden+" #Save With Broken Leiden+ button is clicked
      @identifier.save_broken_leiden_plus_to_xml(params[:ddb_identifier][:leiden_plus], params[:comment])
      @bad_leiden = true
      flash.now[:notice] = "File updated with broken Leiden+ - XML and Preview will be incorrect until fixed"
        @identifier[:leiden_plus] = params[:ddb_identifier][:leiden_plus]
        render :template => 'ddb_identifiers/edit'
    else #Save button is clicked
      begin
        commit_sha = @identifier.set_leiden_plus(params[:ddb_identifier][:leiden_plus],
                                    params[:comment])
        if params[:comment] != nil && params[:comment].strip != ""
          @comment = Comment.new( {:git_hash => commit_sha, :user_id => @current_user.id, :identifier_id => @identifier.origin.id, :publication_id => @identifier.publication.origin.id, :comment => params[:comment], :reason => "commit" } )
          @comment.save
        end
        flash[:notice] = "File updated."
        redirect_to polymorphic_path([@identifier.publication, @identifier],
                                     :action => :edit)
      rescue RXSugar::NonXMLParseError => parse_error
        flash.now[:error] = "Error parsing Leiden+ at line #{parse_error.line}, column #{parse_error.column}"
        @identifier[:leiden_plus] = parse_error.content
        @bad_leiden = true
        @original_commit_comment = params[:comment]
        render :template => 'ddb_identifiers/edit'
      rescue JRubyXML::ParseError => parse_error
        flash[:error] = parse_error.to_str + 
                        ".  This message because the XML created from Leiden+ below did not pass Relax NG validation.  "
        @identifier[:leiden_plus] = params[:ddb_identifier][:leiden_plus]
        #@identifier[:leiden_plus] = parse_error.message
        render :template => 'ddb_identifiers/edit'
      end #begin
    end #when
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
