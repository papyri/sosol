class IdentifiersController < ApplicationController
  def method_missing(method_name, *args)
    identifier = Identifier.find(params[:id])
    if(identifier.class == DDBIdentifier)
      redirect_to :controller => :ddb_identifiers, :action => method_name
    else
      redirect_to :controller => :welcome, :action => "index"
    end
  end
end