class CommentaryCiteIdentifiersController < IdentifiersController
  layout SITE_LAYOUT
  before_filter :authorize
  
  def edit
    find_publication_and_identifier
    @identifier[:action] = 'update'  
  end
  
  def update 
    find_publication_and_identifier
    # targets are set when the cite object was created so the only thing
    # to be updated should be the content
      @identifier.update(params[:wmd-input])
    redirect_to(:action => :preview, :publication_id => @publication.id, :id => @identifier.id) and return
  end
  
  
  def preview
    find_identifier
    @identifier[:html_preview] = @identifier.preview(params)
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
