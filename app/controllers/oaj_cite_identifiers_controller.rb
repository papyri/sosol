class OajCiteIdentifiersController < IdentifiersController
  layout SITE_LAYOUT
  before_filter :authorize
  before_filter :ownership_guard, :only => [:update]


  def create
    @publication = Publication.find(params[:publication_id].to_s)
    
    # use the default collection if one wasn't specified
    urn = params[:urn]
    content = params[:init_value]

    # required params: publication_id, urn, init_value
    unless (@publication && urn)
      flash[:error] = "Unable to create item. Missing urn."
      redirect_to dashboard_url
      return
    end
    
    # make sure we have a valid collection 
    if Cite::CiteLib::get_collection(collection_urn).nil?
      flash[:error] = "Unable to create item. Unknown collection."
      redirect_to dashboard_url
      return
    end

    newobj = OajCiteIdentifier.new_from_supplied(@publication,collection_urn,valid_targets)
    flash[:notice] = "File created."
    expire_publication_cache
    redirect_to polymorphic_path([@identifier.publication, newobj],
                                 :action => :preview) and return
  end

  def preview
    find_identifier
    @identifier[:html_preview] = @identifier.preview
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
