require 'net/http'
require 'jruby_xml'
require 'iconv'

module NumbersRDF
  NUMBERS_SERVER_DOMAIN = 'papyri.info'
  NUMBERS_SERVER_PORT = 80
  NUMBERS_SERVER_BASE_PATH = '/numbers'
  
  NAMESPACE_IDENTIFIER = 'papyri.info'
  
  module NumbersHelper
    class << self
      def identifier_to_local_identifier(identifier)
        identifier.sub(/^#{NAMESPACE_IDENTIFIER}/, '')
      end
      
      def identifier_url_to_identifier(identifier)
        no_scheme = identifier.sub(/^http:\/\//,'')
        no_decorator = no_scheme.sub(/\/(rdf|source)$/,'')
      end
    
      def identifier_to_components(identifier)
        identifier.split('/')
      end

      def identifier_to_path(identifier, decorator)
        local_identifier = identifier_to_local_identifier(identifier)
        url_paths = identifier_to_components(local_identifier)
        url_paths << decorator
        return url_paths.join('/')
      end
      
      def sparql_query_to_path(sparql_query, format = '')
        path = "/mulgara/sparql/?query=" + URI.escape(sparql_query)
        if format != ''
          path += "&format=#{format}"
        end
        return path
      end
      
      def identifier_to_url(identifier)
        if !identifier.blank? && identifier =~ /^#{NAMESPACE_IDENTIFIER}/
          return "http://#{identifier}"
        else
          return nil
        end
      end
      
      def identifier_to_numbers_server_response(identifier, decorator = 'rdf')
        path = identifier_to_path(identifier, decorator)
        response = Net::HTTP.get_response(NUMBERS_SERVER_DOMAIN, path,
                                          NUMBERS_SERVER_PORT)
      end
      
      def sparql_query_to_numbers_server_response(sparql_query, format = '')
        path = sparql_query_to_path(sparql_query, format)
        response = Net::HTTP.get_response(NUMBERS_SERVER_DOMAIN, path,
                                          NUMBERS_SERVER_PORT)
      end
      
      def apply_xpath_to_numbers_server_response(xpath, response)
        if response.code != '200'
          return nil
        else
          return process_numbers_server_response_body(
            Iconv.iconv('UTF-8','LATIN1',response.body).join,
            xpath)
        end
      end
      
      def apply_xpath_to_sparql_query(xpath, sparql_query)
        response = sparql_query_to_numbers_server_response(sparql_query)
        apply_xpath_to_numbers_server_response(xpath, response)
      end
      
      def apply_xpath_to_identifier(xpath, identifier, decorator = 'rdf')
        response = identifier_to_numbers_server_response(identifier, decorator)
        apply_xpath_to_numbers_server_response(xpath, response)
      end

      #Takes an identifier and returns an array of related identifiers from the numbers server.
      def identifier_to_identifiers(identifier)
        results = apply_xpath_to_identifier(
          "/rdf:RDF/rdf:Description/ns1:relation/@rdf:resource", identifier)
        if results.nil?
          return nil
        else
          return [identifier] + results.collect{|r| identifier_url_to_identifier(r)}
        end
      end
      
      def identifier_to_parts(identifier)
        results = apply_xpath_to_identifier(
          "/rdf:RDF/rdf:Description/ns1:hasPart/@rdf:resource", identifier)
        if results.nil?
          return nil
        else
          return results.collect{|r| identifier_url_to_identifier(r)}
        end
      end
      
      # Turns e.g. papyri.info/hgv/P.Amh._2_48 into papyri.info/hgv/123
      def collection_identifier_to_identifiers(identifier)
        results = apply_xpath_to_sparql_query(
          "//*:uri/text()",
          'prefix dc: <http://purl.org/dc/terms/> select ?hgvid from <rmi://localhost/papyri.info#pi> where { ?hgvid dc:identifier <http://' + URI.escape(identifier) + '> . filter regex(str(?hgvid), "^http://papyri.info/hgv/")}'
        )
        if results.nil?
          return nil
        else
          return results.collect{|r| identifier_to_identifiers(identifier_url_to_identifier(r))}.flatten.uniq
        end
      end
      
      def identifier_to_title(identifier)
        result = apply_xpath_to_identifier(
          "/rdf:RDF/rdf:Description/ns1:bibliographicCitation/text()", identifier, 'frbr:Work/rdf'
        )
        return result.nil? ? nil : result.first
      end

      #Takes an array of identifiers and
      #Returns a hash with IDENTIFIER_NAMESPACE (hgv, tm, ddbdp etc)  as the keys and the identifier as the value.
      def identifiers_to_hash(identifiers)
        identifiers_hash = Hash.new
        unless identifiers.nil?
          identifiers.each do |identifier|
            local_identifier = identifier_to_local_identifier(identifier)
            components = identifier_to_components(local_identifier)
            key = components[1]
            identifiers_hash[key] = 
              Array.new() unless identifiers_hash.has_key?(key)
            identifiers_hash[key] << identifier
          end
        end
        return identifiers_hash
      end
    
      def process_numbers_server_response_body(rdf_xml, xpath)
        begin
          return JRubyXML.apply_xpath(rdf_xml, xpath, true).collect do |xpath_result|
            xpath_result[:value]
          end
        rescue NativeException
          return nil
        end
      end
    end
  end
end
