class IdentifiersController < ApplicationController
  def method_missing(method_name, *args)
    identifier = Identifier.find(params[:id])
    redirect_to :controller => identifier.class.to_s.pluralize.underscore, :action => method_name
  end
end