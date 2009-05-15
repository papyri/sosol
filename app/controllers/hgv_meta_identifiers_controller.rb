class HgvMetaIdentifiersController < IdentifiersController
  layout 'site'
  before_filter :authorize
  
  def edit
    find_identifier
    @identifier.get_epidoc_attributes
  end
  
  def update
    find_identifier
    @identifier.set_epidoc(params[:hgv_meta_identifier], params[:comment])
    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 :action => :edit)
  end
  
  protected
    def find_identifier
      @identifier = HGVMetaIdentifier.find(params[:id])
    end
end