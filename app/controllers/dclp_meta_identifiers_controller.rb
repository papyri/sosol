include DclpMetaIdentifierHelper

class DclpMetaIdentifiersController < HgvMetaIdentifiersController

  def edit
    find_identifier
    @identifier.get_epidoc_attributes
    @is_editor_view = true
  end
  
  protected
  
    # Sets the identifier instance variable values
    # - *Params*  :
    #   - +id+ -> id from identifier table of the DCLP Text
    def find_identifier
      @identifier = DCLPMetaIdentifier.find(params[:id].to_s)
    end
end
