class CommentaryCiteIdentifiersController < IdentifiersController
  layout SITE_LAYOUT
  before_filter :authorize
  
  def edit
    find_publication_and_identifier
    @identifier[:action] = 'update'  
    @identifier[:targets] = @identifier.preview_targets(params)
    params[:commentary_text] ||= @identifier.get_commentary_text()
  end
  
  def update 
    find_publication_and_identifier
    # targets are set when the cite object was created so the only thing
    # to be updated should be the content
    begin
      commit_sha = @identifier.update_commentary(params[:commentary_language], params[:commentary_text], params[:comment])
      if params[:comment] != nil && params[:comment].strip != ""
          @comment = Comment.new( {:git_hash => commit_sha, :user_id => @current_user.id, :identifier_id => @identifier.origin.id, :publication_id => @identifier.publication.origin.id, :comment => params[:comment].to_s, :reason => "commit" } )
          @comment.save
      end
      flash[:notice] = "File updated."
      expire_publication_cache
      if %w{new editing}.include?@identifier.publication.status
        flash[:notice] += " Go to the <a href='#{url_for(@identifier.publication)}'>publication overview</a> if you would like to submit."
      end
    rescue JRubyXML::ParseError => parse_error
      flash[:error] = parse_error.to_str + 
          ".  This message is because the XML did not pass validation.  This file was NOT SAVED. "
      redirect_to polymorphic_path([@identifier.publication, @identifier],:action => :edit, :commentary_text => params[:commentary_text])
      return
      
    rescue Cite::CiteError => cite_error
      flash[:error] = "This file was NOT SAVED. "+ cite_error.to_str
      redirect_to polymorphic_path([@identifier.publication, @identifier],:action => :edit, :commentary_text => params[:commentary_text])
      return
    end #begin
    redirect_to polymorphic_path([@identifier.publication, @identifier],:action => :edit)
  end
  
  
  def preview
    find_identifier
    @identifier[:html_preview] = @identifier.preview
  end
    
  protected
    def find_identifier
      @identifier = CommentaryCiteIdentifier.find(params[:id].to_s)
    end
  
    def find_publication_and_identifier
      @publication = Publication.find(params[:publication_id].to_s)
      find_identifier
    end
    
     def find_publication
      @publication = Publication.find(params[:publication_id].to_s)
    end
  
end
