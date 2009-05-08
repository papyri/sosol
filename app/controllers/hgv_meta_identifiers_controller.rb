class HgvMetaIdentifiersController < ApplicationController
  layout 'site'
  
  def edit
    find_identifier
  end
  
  def history
    find_identifier
  end
  
  protected
    def find_identifier
      @identifier = HGVMetaIdentifier.find(params[:id])
    end
end