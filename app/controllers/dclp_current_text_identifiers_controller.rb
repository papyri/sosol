include HGVMetaIdentifierHelper
include DCLPTextIdentifierHelper

class DCLPCurrentTextIdentifiersController < DDBCurrentIdentifiersController
  protected

  # Sets the identifier instance variable values
  # - *Params*  :
  #   - +id+ -> id from identifier table of the DCLP Text
  def find_identifier
    @identifier = DCLPCurrentTextIdentifier.find(params[:id].to_s)
  end
end
