class AjaxProxyController < ApplicationController
  def proxy
    response = NumbersRDF::NumbersHelper.identifier_to_numbers_server_response(params[:id].to_s, 'json')
    if response.code != '200'
      @response = nil
    else
      @response = response.body
    end
  end
  
  def sparql
    response = NumbersRDF::NumbersHelper.sparql_query_to_numbers_server_response(params[:query].to_s, 'json')
    if response.code != '200'
      @response = nil
    else
      @response = response.body
    end
    
    render :template => 'ajax_proxy/proxy'
  end
  
  def hgvnum

    related_identifiers = NumbersRDF::NumbersHelper.collection_identifier_to_identifiers(params[:identifier].to_s)

    if related_identifiers.nil?
      render :text => "no related identifiers" 
    else
      render :text => "#{related_identifiers.first}"
    end

  end
  
  # Gets the HTTP response from PN solr query
  def get_bibliography
    searchText = (params[:searchText].to_s)
    #replace space with + to match PN search
    searchText = searchText.split(" ").join("+")

    begin
      built_uri = 'http://papyri.info/solrbiblio/select/?q=' + searchText + '&wt=json&start=0&rows=999&sort=date+asc,sort+asc'

      response = Net::HTTP.get_response(URI("#{built_uri}"))

      render :text => response.body
    rescue ::Timeout::Error => e
      render :text =>  "rescue timeout bibliography call" 
    rescue
      render :text =>  "rescue generic bibliography call"
    end
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
            :content => params[:content].to_s,
            :type => params[:type].to_s,
            :direction => params[:direction].to_s
          }
        )
      rescue EOFError
        get_xsugar_response(params)
      end
    end
end
