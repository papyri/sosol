class HgvMetaIdentifiersController < ApplicationController
  layout 'site'
  
  def edit
    find_identifier
    @identifier.load_epidoc_from_file
  end
  
  def history
    find_identifier
  end
  
  protected
    def find_identifier
      @identifier = HGVMetaIdentifier.find(params[:id])
    end
end