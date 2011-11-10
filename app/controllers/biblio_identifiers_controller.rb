include BiblioIdentifierHelper
class BiblioIdentifiersController < IdentifiersController
  # @RB: please see to that there all the standard actions available, such as update, preview and edit and that they have access to the identifier record as well as the EpiDoc
  def edit
    @is_editor_view = true
    find_identifier    
  end
  
  def preview
    @is_editor_view = true
    find_identifier
  end
  
  protected
  
  def find_identifier
    @identifier = BiblioIdentifier.find(params[:id])
  end
  
  def getBiblioPath biblioId
    'Biblio/' + (biblioId.to_i / 1000.0).ceil.to_s + '/'  + biblioId.to_s + '.xml' 
  end

end
