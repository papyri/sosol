class OacIdentifiersController < IdentifiersController
  layout SITE_LAYOUT
  before_filter :authorize
  
  def edit
    redirect_to :action =>"editxml",:id=>params[:id]
  end
  
  def preview
    find_identifier
    @identifier[:html_preview] = @identifier.preview(params)
  end
  
  protected
    def find_identifier
      @identifier = OACIdentifier.find(params[:id])
    end
  
    def find_publication_and_identifier
      @publication = Publication.find(params[:publication_id])
      find_identifier
    end
    
     def find_publication
      @publication = Publication.find(params[:publication_id])
    end
end
