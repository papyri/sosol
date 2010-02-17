require 'net/http'
require 'jruby_xml'
require 'iconv'

module NumbersRDF
  NUMBERS_SERVER_DOMAIN = 'dev.papyri.info'
  NUMBERS_SERVER_PORT = 80
  NUMBERS_SERVER_BASE_PATH = '/numbers'
  
  # OAI identifiers should be in the form scheme ":" namespace-identifier ":" local-identifier
  OAI_SCHEME = 'oai'
  OAI_NAMESPACE_IDENTIFIER = 'papyri.info'
  OAI_IDENTIFIER_PREFIX = "#{OAI_SCHEME}:#{OAI_NAMESPACE_IDENTIFIER}"
  PREFIX = "#{OAI_IDENTIFIER_PREFIX}:identifiers"
  
  module NumbersHelper
    class << self
      # TODO: after move from dev.papyri.info to papyri.info can probably use NUMBERS_SERVER_DOMAIN
      def identifier_to_local_identifier(identifier)
        identifier.sub(/^#{OAI_NAMESPACE_IDENTIFIER}/, '')
      end
      
      def identifier_url_to_identifier(identifier)
        no_scheme = identifier.sub(/^http:\/\//,'')
        no_decorator = no_scheme.sub(/\/(rdf|source)$/,'')
      end
    
      def identifier_to_components(identifier)
        identifier.split('/')
      end

      def identifier_to_path(identifier)
        local_identifier = identifier_to_local_identifier(identifier)
        url_paths = identifier_to_components(local_identifier)
        url_paths << 'rdf'
        return url_paths.join('/')
      end

      # FIXME: this should eventually go to e.g. /source or http://papyri.info/navigator/full/apis_columbia_p204 or something. Will be used to replace "View in PN" link constructed in app/views/identifiers/_pn_link.haml
      def identifier_to_url(identifier)
        return 'http://' + NUMBERS_SERVER_DOMAIN + ':' + 
                NUMBERS_SERVER_PORT.to_s + identifier_to_path(identifier)
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
          return [identifier] + process_numbers_server_response_body(
            Iconv.iconv('UTF-8','LATIN1',response.body).join)
        end
      end
    
      def identifiers_to_hash(identifiers)
        identifiers_hash = Hash.new
        identifiers.each do |identifier|
          local_identifier = identifier_to_local_identifier(identifier)
          components = identifier_to_components(local_identifier)
          key = components[1]
          identifiers_hash[key] = 
            Array.new() unless identifiers_hash.has_key?(key)
          identifiers_hash[key] << identifier
        end
        return identifiers_hash
      end
    
      def process_numbers_server_response_body(rdf_xml)
        identifiers = []
        ore_describes_path = "/rdf:RDF/rdf:Description/ns1:relation"
        JRubyXML.apply_xpath(rdf_xml, ore_describes_path, true).each do |ore_describes|
          resource = ore_describes[:attributes]['rdf:resource']
          identifiers << identifier_url_to_identifier(resource)
        end
        
        return identifiers
      end
    end
  end
end