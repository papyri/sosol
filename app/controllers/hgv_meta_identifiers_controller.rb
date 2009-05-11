class HgvMetaIdentifiersController < ApplicationController
  layout 'site'
  
  def edit
    find_identifier
    @identifier.load_epidoc_from_file
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