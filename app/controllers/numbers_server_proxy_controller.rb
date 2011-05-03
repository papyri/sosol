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
    response = get_xsugar_response(params)
    
    render :text => response.body, :status => response.code
  end
  
  protected
    def get_xsugar_response(params)
      begin
        return Net::HTTP.post_form(URI.parse(XSUGAR_STANDALONE_URL),
          {
            :content => params[:content],
            :type => params[:type],
            :direction => params[:direction]
          }
        )
      rescue EOFError
        get_xsugar_response(params)
      end
    end
end
