class OajCiteIdentifiersController < IdentifiersController
  layout Sosol::Application.config.site_layout
  before_filter :authorize
  before_filter :ownership_guard, :only => [:edit, :update, :destroy]


  # create is not exposed for OajCiteIdentiifers .. these identifiers are for prototype functionality
  # and can currently only be created through conversion of an OaCiteIdentifier which was created via
  # import of a Hypothes.is annotation
  # @see oa_cite_identifiers_controller#convert

  def edit
    find_identifier
    @is_editor_view = true
  end

  def update
    find_identifier
    # NB use of xml_content nomenclature is just to allow us to make use of
    # the validate functionality which runs a preprocess step -- in this
    # case a JSON parse
    xml_content = params[@identifier.class.to_s.underscore][:xml_content].gsub(/\r\n?/, "\n")
    begin
      commit_sha = @identifier.set_xml_content(xml_content,:comment => params[:comment])
      if params[:comment] != nil && params[:comment].strip != ""
        @comment = Comment.new( {:git_hash => commit_sha, :user_id => @current_user.id, :identifier_id => @identifier.origin.id, :publication_id => @identifier.publication.origin.id, :comment => params[:comment].to_s, :reason => "commit" } )
        @comment.save
      end
      
      flash[:notice] = "File updated."
      expire_publication_cache
      if %w{new editing}.include?@identifier.publication.status
        flash[:notice] += " Go to the <a href='#{url_for(@identifier.publication)}'>publication overview</a> if you would like to submit."
      end
    rescue => parse_error
      Rails.logger.info(parse_error.backtrace)
      flash[:error] = "#{parse_error}. This file was NOT SAVED."
    end
    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 :action => :edit) and return
  end

  def preview
    find_identifier
  end

  def destroy
    find_identifier 
    name = @identifier.title
    pub = @identifier.publication
    @identifier.destroy
    
    flash[:notice] = name + ' was successfully removed from your publication.'
    redirect_to pub
    return
  end

  protected
    def find_identifier
      @identifier = OajCiteIdentifier.find(params[:id].to_s)
    end
  
    def find_publication_and_identifier
      @publication = Publication.find(params[:publication_id].to_s)
      find_identifier
    end
    
     def find_publication
      @publication = Publication.find(params[:publication_id].to_s)
    end
  
end
