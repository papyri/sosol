class EagleTransCtsIdentifiersController < EpiTransCtsIdentifiersController
  
  protected
    def find_identifier
      @identifier = EagleTransCTSIdentifier.find(params[:id].to_s)
    end
    
end
