class AjaxProxyController < ApplicationController
  def proxy
    response = NumbersRDF::NumbersHelper.identifier_to_numbers_server_response(params[:id].to_s, 'json')
    render :text => response.body, :status => response.code
  end
  
  def sparql
    response = NumbersRDF::NumbersHelper.sparql_query_to_numbers_server_response(params[:query].to_s, 'json')
    render :text => response.body, :status => response.code
  end
  
  def hgvnum

    related_identifiers = NumbersRDF::NumbersHelper.collection_identifier_to_identifiers(params[:identifier].to_s)

    if related_identifiers.nil?
      render :text => "no related identifiers" 
    else
      render :text => "#{related_identifiers.first}"
    end

  end

  def js
    built_uri = 'http://papyri.info/js/' + params[:query].to_s
    response = Net::HTTP.get_response(URI("#{built_uri}"))
    render :js => response.body, :layout => false
  end

  def css
    built_uri = 'http://papyri.info/css/' + params[:query].to_s
    response = Net::HTTP.get_response(URI("#{built_uri}"))
    render :text => response.body, :content_type => 'text/css', :layout => false
  end

  def images
    built_uri = 'http://papyri.info/images/' + params[:query].to_s
    response = Net::HTTP.get_response(URI("#{built_uri}"))
    render :text => response.body, :content_type => response['Content-Type'], :layout => false
  end

  # Gets the HTTP response from PN solr query
  def get_bibliography
    searchText = (params[:searchText].to_s)
    #replace space with + to match PN search
    searchText = searchText.split(" ").join("+")

    begin
      built_uri = 'http://papyri.info/solrbiblio/select/?q=' + searchText + '&wt=json&start=0&rows=999&sort=date+asc,sort+asc'

      response = Net::HTTP.get_response(URI("#{built_uri}"))

      render :text => response.body.html_safe
    rescue ::Timeout::Error => e
      render :text =>  "rescue timeout bibliography call" 
    rescue
      render :text =>  "rescue generic bibliography call"
    end
  end
  
  def xsugar
    response = get_xsugar_response(params)
    
    render :text => response.body.html_safe, :status => response.code
  end
  
  protected
    def get_xsugar_response(params)
      begin
        if !Sosol::Application.config.respond_to?(:xsugar_standalone_url)
          Rails.logger.info("Returning nil for XSugar proxy request as XSugar standalone url is not set")
          return nil
        else
          return Net::HTTP.post_form(URI.parse(Sosol::Application.config.xsugar_standalone_url),
            {
              :content => params[:content].to_s,
              :type => params[:type].to_s,
              :direction => params[:direction].to_s
            }
          )
        end
      rescue EOFError
        get_xsugar_response(params)
      end
    end
end
