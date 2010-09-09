class NumbersServerProxyController < ApplicationController
  def proxy
    response = NumbersRDF::NumbersHelper.identifier_to_numbers_server_response(params[:id], 'json')
    if response.code != '200'
      @response = nil
    else
      @response = response.body
    end
  end
end
