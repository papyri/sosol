class IdentifiersController < ApplicationController
  def method_missing(method_name, *args)
    identifier = Identifier.find(params[:id])
    redirect_to :controller => identifier.class.to_s.pluralize.underscore, :action => method_name
  end
  
  # GET /publications/1/xxx_identifiers/1/editxml
  def editxml
    find_identifier
    @identifier[:xml_content] = @identifier.xml_content
  end
end