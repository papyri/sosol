include HgvMetaIdentifierHelper
include DclpTextIdentifierHelper

class DclpTextIdentifiersController < DdbIdentifiersController
  protected

  # Sets the identifier instance variable values
  # - *Params*  :
  #   - +id+ -> id from identifier table of the DCLP Text
  def find_identifier
    @identifier = DCLPTextIdentifier.find(params[:id].to_s)
  end
end
