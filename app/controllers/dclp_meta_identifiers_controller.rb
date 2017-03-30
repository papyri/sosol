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
        @update = 'No preview available for ' + params[:biblio]
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

  # - GET /publications/1/ddb_identifiers/1/preview
  # - Provides preview of what the DDB Text XML from the repository will look like with PN Stylesheets applied
  def preview
    find_identifier
    @identifier[:html_preview] = @identifier.preview
    @is_editor_view = true
    render :template => 'ddb_identifiers/preview'
  end

  protected

    # Sets the identifier instance variable values
    # - *Params*  :
    #   - +id+ -> id from identifier table of the DCLP Text
    def find_identifier
      @identifier = DCLPMetaIdentifier.find(params[:id].to_s)
    end

    def prune_params
      super

      if params[:hgv_meta_identifier]

        # get rid of either collection or of collectionList
        if params[:hgv_meta_identifier][:collectionList]
          params[:hgv_meta_identifier][:collectionList].delete_if{|key, collection| collection.empty?}
          if params[:hgv_meta_identifier][:collectionList].length == 1
            params[:hgv_meta_identifier][:collection] = params[:hgv_meta_identifier][:collectionList].shift[1]
            params[:hgv_meta_identifier].delete :collectionList
          end
        end

        # get rid of empty extra/biblScopes/passages for editions/biblio
        if params[:hgv_meta_identifier][:edition]
          params[:hgv_meta_identifier][:edition].each_value{|edition|
            if edition[:children]
              # delete title if there is a biblio id
              if edition[:children][:link] && edition[:children][:link] && edition[:children][:link][:value] && (edition[:children][:link][:value] =~ /\A\d+\Z/)
                edition[:children].delete :title
              end

              if edition[:children][:extra]
                edition[:children][:extra].each_pair{|key, extra|
                  if extra[:value].empty?
                    edition[:children][:extra].delete key
                  end
                }
              end
            end
          }
        end

        # get rid of empty contentText fields
        if params[:hgv_meta_identifier][:contentText]
          params[:hgv_meta_identifier][:contentText].delete_if{|key, value| value.empty? }
        end

        # get rid of empty printed illustrations and online resources
        if params[:hgv_meta_identifier][:printedIllustration]
          params[:hgv_meta_identifier][:printedIllustration].delete_if{|key, value| value.empty? }
        end
        if params[:hgv_meta_identifier][:onlineResource]
          params[:hgv_meta_identifier][:onlineResource].delete_if{|key, value| !value[:children] || !value[:children][:link] || !value[:children][:link][:attributes] || !value[:children][:link][:attributes][:target] || value[:children][:link][:attributes][:target].empty? }
        end

      end
    end

    def complement_params
      super

      if params[:hgv_meta_identifier]

        # contentText: add type attributes for terms according to their position number
        if params[:hgv_meta_identifier][:contentText]
          params[:hgv_meta_identifier][:contentText].each_pair{|key, value|
            type = case key.to_i
            when 0, 1
              'description'
            when 2, 3
              'religion'
            when 4, 5
              'culture'
            else
              ''
            end
            params[:hgv_meta_identifier][:contentText][key] = {'value' => value, 'attributes' => {'class' => type}}
          }
        end

        # contentText: add overview
        if params[:hgv_meta_identifier][:overview]
          overview = {'value' => params[:hgv_meta_identifier][:overview], 'attributes' => {'class' => 'overview'}}
          if params[:hgv_meta_identifier][:contentText]
            params[:hgv_meta_identifier][:contentText]['overview'] = overview
          else
            params[:hgv_meta_identifier][:contentText] = {'overview' => overview}
          end
          params[:hgv_meta_identifier].delete :overview
        end

        # edition link to papyri.info
        if params[:hgv_meta_identifier][:edition]
          params[:hgv_meta_identifier][:edition].each {|key, edition|
            if edition[:children] && edition[:children][:link] && (/\A\d+\Z/ =~ edition[:children][:link][:value])
                edition[:children][:link][:value] = 'http://papyri.info/biblio/' + edition[:children][:link][:value]
            end
          }
        end

      end
    end

end
