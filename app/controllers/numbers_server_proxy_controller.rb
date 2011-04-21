class NumbersServerProxyController < ApplicationController
  def proxy
    response = NumbersRDF::NumbersHelper.identifier_to_numbers_server_response(params[:id], 'json')
    if response.code != '200'
      @response = nil
    else
      @response = response.body
    end
  end
  
  def sparql
    response = NumbersRDF::NumbersHelper.sparql_query_to_numbers_server_response(params[:query], 'json')
    if response.code != '200'
      @response = nil
    else
      @response = response.body
    end
    
    render :template => 'numbers_server_proxy/proxy'
  end
  
  def xsugar
    response = Net::HTTP.post_form(URI.parse(XSUGAR_STANDALONE_URL),
      {
        :content => params[:content],
        :type => params[:type],
        :direction => params[:direction]
      }
    )
    
    @response = response.body
    
    render :template => 'numbers_server_proxy/proxy'
  end
end
