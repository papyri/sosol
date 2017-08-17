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
    data_array = []
    if !params[:term].nil? && /\A[^\d][^\d][^\d][^\d].*\Z/.match(params[:term])
      data = exist('http://localhost:8080/exist/apps/papyrillio/autocomplete_json.xml?term=' + params[:term])
      data.each do |key, value|
        if /\Ab\d+\Z/.match(key)
          data_array.push({:label => value, :value => key[1..-1]})
        end
      end
    end
    render json: data_array, content_type: 'application/json'
  end

  # Call to test
  # localhost:3000/dclp_meta_identifiers/work_autocomplete=Aristo
  def ancient_author_autocomplete
    data = {}
    if !params[:term].nil? && /\A[^\d]{4}.*\Z/.match(params[:term])
      data = exist 'http://localhost:8080/exist/apps/papyrillio/autocompleteAncientAuthors_json.xml?term=' + params[:term]
      if data['author'].kind_of? Hash
        data = [data['author']]
      else
        data = data['author']
      end
    end
    render json: data, content_type: 'application/json'
  end

  def exist url
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth("admin", "papy")
    response = http.request(request)
    JSON.parse(response.body)
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
          params[:hgv_meta_identifier][:onlineResource].delete_if{|key, value| !value.kind_of?(Hash) || !value[:children] || !value[:children][:link] || !value[:children][:link][:attributes] || !value[:children][:link][:attributes][:target] || value[:children][:link][:attributes][:target].empty? }
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
        if params[:hgv_meta_identifier][:overview] && !params[:hgv_meta_identifier][:overview].empty?
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

        if params[:hgv_meta_identifier][:work]
          # add xor ids and excludes
          if params[:hgv_meta_identifier][:workAlternative] && params[:hgv_meta_identifier][:workAlternative] == 'alternative' && params[:hgv_meta_identifier][:work] && params[:hgv_meta_identifier][:work].length > 1
            listOfAlternatives = []
            params[:hgv_meta_identifier][:work].each {|key, work|
              id = 'work_' + key
              work[:attributes][:id] = id
              listOfAlternatives << id
            }
            params[:hgv_meta_identifier][:work].each {|key, work|
              id = work[:attributes][:id]
              work[:attributes][:exclude] = listOfAlternatives.select{ |excludeId| excludeId != id }.join(' ')
            }
          end

          # author & work: generate links to tlg, phi, stoa, tm and cwkb
          params[:hgv_meta_identifier][:work].each {|key, work|
            if work[:children]
              if work[:children][:author]
                refList = {}
                if work[:children][:author][:attributes] && work[:children][:author][:attributes][:ref] && work[:children][:author][:attributes][:ref].kind_of?(Hash)
                  refList = work[:children][:author][:attributes][:ref]
                end
                if work[:children][:author][:tlg] && work[:children][:author][:tlg] =~ /\d\d\d\d/
                  refList[:tlg] = 'http://data.perseus.org/catalog/urn:cts:greekLit:tlg' +  work[:children][:author][:tlg]
                end
                if work[:children][:author][:phi] && work[:children][:author][:phi] =~ /\d\d\d\d/
                  refList[:phi] = 'http://data.perseus.org/catalog/urn:cts:latinLit:phi' + work[:children][:author][:phi]
                end
                if work[:children][:author][:stoa] && work[:children][:author][:stoa] =~ /\d\d\d\d/
                  refList[:stoa] = 'http://catalog.perseus.org/catalog/urn:cts:latinLit:stoa' + work[:children][:author][:stoa]
                end
                if work[:children][:author][:cwkb] && work[:children][:author][:cwkb] =~ /\d+/
                  refList[:cwkb] = 'http://cwkb.org/author/id/' +  work[:children][:author][:cwkb] + '/rdf'
                end
                work[:children][:author][:attributes][:ref] = refList.invert.invert
              end
              if work[:children][:title]
                refList = {}
                if work[:children][:title][:attributes] && work[:children][:title][:attributes][:ref] && work[:children][:title][:attributes][:ref].kind_of?(Hash)
                  refList = work[:children][:title][:attributes][:ref]
                end
                if work[:children][:title][:tm] && work[:children][:title][:tm] =~ /\d+/
                  refList[:tm] = 'http://www.trismegistos.org/authorwork/' +  work[:children][:title][:tm]
                end
                if work[:children][:title][:cwkb] && work[:children][:title][:cwkb] =~ /\d+/
                  refList[:cwkb] = 'http://cwkb.org/work/id/' +  work[:children][:title][:cwkb] + '/rdf'
                end
                if work[:children][:title][:stoa] && work[:children][:title][:stoa] =~ /\d+/
                  if work[:children][:author] && work[:children][:author][:stoa] && work[:children][:author][:stoa] =~ /\d\d\d\d/
                    refList[:stoa] = 'http://catalog.perseus.org/catalog/urn:cts:latinLit:stoa' + work[:children][:author][:stoa] + '.stoa' + work[:children][:title][:stoa]
                  end
                end
                if work[:children][:title][:tlg] && work[:children][:title][:tlg] =~ /\d+/
                  if work[:children][:author] && work[:children][:author][:tlg] && work[:children][:author][:tlg] =~ /\d\d\d\d/
                    refList[:tlg] = 'http://catalog.perseus.org/catalog/urn:cts:greekLit:tlg' + work[:children][:author][:tlg] + '.tlg' + work[:children][:title][:tlg]
                  end
                end
                work[:children][:title][:attributes][:ref] = refList.invert.invert
              end
            end
          }
        end

      end
    end

end
