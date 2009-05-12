require 'net/http'

module NumbersRDF
  NUMBERS_SERVER_DOMAIN = 'apptest.cul.columbia.edu'
  NUMBERS_SERVER_PORT = 8082
  NUMBERS_SERVER_BASE_PATH = '/numbers'
  # OAI identifiers should be in the form scheme ":" namespace-identifier ":" local-identifier
  OAI_SCHEME = 'oai'
  OAI_NAMESPACE_IDENTIFIER = 'papyri.info'
  OAI_IDENTIFIER_PREFIX = "#{OAI_SCHEME}:#{OAI_NAMESPACE_IDENTIFIER}:"
  
  module NumbersHelper
    def identifier_to_local_identifier(identifier)
      identifier.sub(/^#{OAI_IDENTIFIER_PREFIX}/, '')
    end
    
    def identifier_to_components(identifier)
      identifier.split(':')
    end

    def identifier_to_path(identifier)
      local_identifier = identifier_to_local_identifier(identifier)
      url_paths = [NUMBERS_SERVER_BASE_PATH] + 
                  identifier_to_components(local_identifier)
      return url_paths.join('/')
    end

    def identifier_to_url(identifier)
      return 'http://' + NUMBERS_SERVER_DOMAIN + ':' + 
              NUMBERS_SERVER_PORT + identifier_to_path(identifier)
    end
    
    def identifier_to_numbers_server_response(identifier)
      path = identifier_to_path(identifier)
      response = Net::HTTP.get_response(NUMBERS_SERVER_DOMAIN, path,
                                        NUMBERS_SERVER_PORT)
    end
    
    def identifier_to_identifiers(identifier)
      response = identifier_to_numbers_server_response(identifier)

      if response.code != '200'
        return nil
      else
        return process_numbers_server_response_body(response.body)
      end
    end
    
    def process_numbers_server_response_body(rdf_xml)
      puts rdf_xml
      doc = REXML::Document.new(rdf_xml)
      identifiers = []
      ore_describes_path = "/rdf:RDF/rdf:Description/ore:aggregates/rdf:Description/ore:describes"
      REXML::XPath.each(doc, ore_describes_path) do |ore_describes|
        identifiers << ore_describes.attributes['rdf:resource']
      end
      
      return identifiers
    end
  end
end