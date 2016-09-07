include DclpMetaIdentifierHelper

require 'net/http'

class DclpMetaIdentifiersController < HgvMetaIdentifiersController

  def edit
    find_identifier
    @identifier.get_epidoc_attributes
    @is_editor_view = true
  end

  # Provides a small data preview snippets (values for when, notBefore and notAfter as well as the hgv formatted value) for display within the hgv metadata editor
  # Assumes that hgv metadata is passed in via post and uses the values containd in hash entry »:textDate« to generate preview snippets for hgv date.
  # Side effect on +@update+
  def biblio_preview
    @update = 'No preview available';
    if !params[:biblio].nil? && /\A\d+\Z/.match(params[:biblio])
      uri = URI('http://localhost:8080/exist/apps/papyrillio/snippet.html?biblio=' + params[:biblio])
      # @update = Net::HTTP.get(uri).gsub(/(<html[^>]*>|<[^>]*html>)/, '')

      response = Net::HTTP.get_response(uri)
      if response.code == '200'
        @update = response.body.gsub(/(<html[^>]*>|<[^>]*html>)/, '')
      else
        @update = 'No preview available for ' + params[:biblio];
      end
    end
  end

  # Call to test
  # localhost:3000/dclp_meta_identifiers/biblio_autocomplete?term=Clio
  def biblio_autocomplete
    data = {}
    if !params[:term].nil? && /\A[^\d][^\d][^\d][^\d].*\Z/.match(params[:term])
      uri = URI.parse('http://localhost:8080/exist/apps/papyrillio/autocomplete_json.xml?term=' + params[:term])
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)
      request.basic_auth("admin", "papy")
      response = http.request(request)
      data = JSON.parse(response.body)

      data_array = []
      data.each do |key, value|
        if /\Ab\d+\Z/.match(key)
          data_array.push({:label => value, :value => key[1..-1]})
        end
      end

    end
    render json: data_array, content_type: 'application/json'
  end

  protected

    # Sets the identifier instance variable values
    # - *Params*  :
    #   - +id+ -> id from identifier table of the DCLP Text
    def find_identifier
      @identifier = DCLPMetaIdentifier.find(params[:id].to_s)
    end
end
