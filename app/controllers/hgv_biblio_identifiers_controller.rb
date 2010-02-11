class HgvBiblioIdentifiersController < HgvMetaIdentifiersController
  before_filter :find_identifier, :only => [:edit, :update]

  def edit
    @identifier.retrieve_bibliographical_data # todo: should actually be called implicitly during initialisation time
  end

  def update
    comment = (params[:comment] && (params[:comment].strip.length > 0)) ? params[:comment].strip : 'update bibliographical information'
    @identifier.set_epidoc params[:hgv_biblio_identifier], comment
    save_comment comment
    redirect_to polymorphic_path([@identifier.publication, @identifier],
                                 :action => :edit)
  end

  protected

    def find_identifier
      @identifier = HGVBiblioIdentifier.find(params[:id])
    end
end