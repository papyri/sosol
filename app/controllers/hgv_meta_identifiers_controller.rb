class HgvMetaIdentifiersController < ApplicationController
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
  
  def history
    find_identifier
    @identifier.get_commits
    # use a superclass view
    render :template => 'identifiers/history'
  end
  
  protected
    def find_identifier
      @identifier = HGVMetaIdentifier.find(params[:id])
    end
end