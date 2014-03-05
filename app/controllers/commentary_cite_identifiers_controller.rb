class CommentaryCiteIdentifiersController < IdentifiersController
  layout Sosol::Application.config.site_layout
  before_filter :authorize
  before_filter :ownership_guard, :only => [:update]

  def create
    @publication = Publication.find(params[:publication_id].to_s)
    
    # use the default collection if one wasn't specified
    collection_urn = params[:urn] || Cite::CiteLib.get_default_collection_urn()
        
    # support either :init_value or :valid_targets to specify initial targets
    # latter is for compatibility with prototype cts oac annotation ui
    valid_targets = params[:valid_targets] || params[:init_value]

    # required params: publication_id, urn, init_value
    unless (@publication && collection_urn && valid_targets)
      flash[:error] = "Unable to create commentary item. Missing urn and initial value."
      redirect_to dashboard_url
      return
    end
    
    # make sure we have a valid collection 
    if Cite::CiteLib::get_collection(collection_urn).nil?
      flash[:error] = "Unable to create commentary item. Unknown collection."
      redirect_to dashboard_url
      return
    end

    conflicts = []
    for pubid in @publication.identifiers do 
      ## only allow one commentary item per target and collection
      if (pubid.kind_of?(CommentaryCiteIdentifier) && 
          pubid.collection == Cite::CiteLib.get_collection_urn(collection_urn) &&
          pubid.is_match?(valid_targets))
        conflicts << pubid
      end
    end 
    
    if (conflicts.length > 0) 
      flash[:notice] = "You already are editing a commentary for this target."
      redirect_to polymorphic_path([@publication, conflicts[0]],:action => :edit)
      return
    end
    
    @identifier = CommentaryCiteIdentifier.new_from_template(@publication,collection_urn,valid_targets)
    redirect_to polymorphic_path([@publication, @identifier],:action => :edit)

  end

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
