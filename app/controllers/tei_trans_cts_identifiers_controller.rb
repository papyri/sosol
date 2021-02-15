class TeiTransCtsIdentifiersController < IdentifiersController
  layout Sosol::Application.config.site_layout
  before_filter :authorize
  # require 'xml'
  # require 'xml/xslt'
  
  
  def edit
    find_identifier
    #find text for preview
    @identifier[:text_html_preview] = @identifier.related_text.preview
  end
  
  def editxml
    find_identifier
    @identifier[:xml_content] = @identifier.xml_content
    @is_editor_view = true
    render :template => 'tei_trans_cts_identifiers/editxml'
  end
  
    
  def create_from_selector
    publication = Publication.find(params[:publication_id].to_s)
    edition = params[:edition_urn]
    # if no edition, just use a fake one for use in path processing
    
    collection = params[:CTSIdentifierCollectionSelect]
    
    if (params[:commit] == "Create Translation")
      lang = params[:create_lang]
      # if the inventory doesn't have any edition for the translation then it's a new edition
      # whose urn will be in the CTSIdentifierEditionSelect param
      if (edition.nil?)
        edition = params[:CTSIdentifierEditionSelect]
      end
      @identifier =  TeiTransCTSIdentifier.new_from_template(publication,collection,edition,'translation',lang)
    else
      begin
        @identifier = TeiTransCTSIdentifier.new_from_inventory(publication,collection,edition,'translation')
      rescue StandardError => e
        flash[:notice] = e.to_s
        redirect_to dashboard_url
        return
      end
    end
    flash[:notice] = "File created."
    expire_publication_cache
    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 :action => :edit) and return
  end

  def update
    find_identifier
    @original_commit_comment = ''
    #if user fills in comment box at top, it overrides the bottom
    if params[:commenttop] != nil && params[:commenttop].strip != ""
      params[:comment] = params[:commenttop]
    end
    begin
      commit_sha = @identifier.set_xml_content(params[:tei_cts_identifier].to_s,
                                    params[:comment].to_s)
      if params[:comment] != nil && params[:comment].strip != ""
          @comment = Comment.new( {:git_hash => commit_sha, :user_id => @current_user.id, :identifier_id => @identifier.origin.id, :publication_id => @identifier.publication.origin.id, :comment => params[:comment].to_s, :reason => "commit" } )
          @comment.save
      end
      flash[:notice] = "File updated."
      expire_publication_cache
      if %w{new editing}.include?@identifier.publication.status
          flash[:notice] += " Go to the <a href='#{url_for(@identifier.publication)}'>publication overview</a> if you would like to submit."
      end
        
      redirect_to polymorphic_path([@identifier.publication, @identifier],
                                     :action => :edit)
      rescue JRubyXML::ParseError => parse_error
        flash.now[:error] = parse_error.to_str + 
          ".  This message is because the XML did not pass Relax NG validation.  This file was NOT SAVED. "
        render :template => 'tei_trans_cts_identifiers/edit'
      end #begin
  end
  
  # GET /publications/1/ddb_identifiers/1/preview
  def preview
    find_identifier
    
    if @identifier.xml_content.to_s.empty?
      flash[:error] = "XML content is empty, unable to preview."
      redirect_to polymorphic_url([@identifier.publication, @identifier], :action => :editxml)
      return
    end
    
    @identifier_html_preview = @identifier.preview
  end
  
  
  protected
    def find_identifier
      @identifier = TeiTransCTSIdentifier.find(params[:id].to_s)
    end
end
