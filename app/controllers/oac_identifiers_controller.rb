class OacIdentifiersController < IdentifiersController
  layout SITE_LAYOUT
  before_filter :authorize
  
  def edit
      redirect_to(:controller => 'cts_oac_identifiers',
        :publication_id => params[:publication_id],
        :id => params[:id],
        :action => 'edit',
        :annotation_uri => params[:annotation_uri])
  end
  
  def preview
    redirect_to(:controller => 'cts_oac_identifiers',
        :publication_id => params[:publication_id],
        :id => params[:id],
        :action => 'preview',
        :annotation_uri => params[:annotation_uri])
  end
  
  protected
    def find_identifier
      @identifier = OACIdentifier.find(params[:id].to_s)
    end
  
    def find_publication_and_identifier
      @publication = Publication.find(params[:publication_id].to_s)
      find_identifier
    end
    
     def find_publication
      @publication = Publication.find(params[:publication_id].to_s)
    end
end
