include BiblioIdentifierHelper
class BiblioIdentifiersController < IdentifiersController

  # @RB: please see to that there all the standard actions available, such as update, preview and edit and that they have access to the identifier record as well as the EpiDoc
  def edit
    find_identifier    
  end
  
  def preview
    find_identifier
  end
  
  protected
  
  def find_identifier
    @identifier = BiblioIdentifier.new
  end

end
