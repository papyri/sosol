class CommentaryCiteIdentifiersController < IdentifiersController
  layout Sosol::Application.config.site_layout
  before_filter :authorize
  before_filter :ownership_guard, :only => [:update]


  # Create a new CommentaryCiteIdentifier from an existing Annotation
  # there is no difference between create_from_annotation and create other than
  # create_from_annotation supports GET
  # - *Params* :
  #   - +publication_id+ -> String identifier for the parent publication
  #   - +init_value+ -> List of string URI values of the targets of the commentary annotation
  def create_from_annotation
    create()
  end
  
  # Create a new CommentaryCiteIdentifier
  # - *Params* :
  #   - +publication_id+ -> String identifier for the parent publication
  #   - +init_value+ -> List of string URI values of the targets of the commentary annotation
  def create
    @publication = Publication.find(params[:publication_id].to_s)
    
    valid_targets = params[:init_value]

    # required params: publication_id, init_value
    unless (@publication && valid_targets)
      flash[:error] = "Unable to create commentary item. Missing initial value."
      redirect_to dashboard_url
      return
    end
    
    @identifier = CommentaryCiteIdentifier.new_from_template(@publication, true)
    @identifier.update_targets(params[:init_value],"Set targets from init.")
    redirect_to polymorphic_path([@publication, @identifier],:action => :edit)

  end

  def edit
    find_publication_and_identifier
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
    @html_preview = JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(@identifier.xml_content),
      JRubyXML.stream_from_file(File.join(Rails.root,
        %w{data xslt cite commentary_cite_html_preview.xsl})),
        params)
  end

  def destroy
    find_identifier 
    remaining = @identifier.publication.identifiers.select { |i| 
      i != @identifier 
    }
    if (remaining.size == 0)
      flash[:error] = "This would leave the publication without any identifiers."
    end
    name = @identifier.title
    pub = @identifier.publication
    @identifier.destroy
    
    flash[:notice] = name + ' was successfully removed from your publication.'
    redirect_to pub
    return
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
