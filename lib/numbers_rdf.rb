require 'net/http'
require 'jruby_xml'

module NumbersRDF
  # Top-level namespace used for identifiers, e.g. 'papyri.info' in 'papyri.info/hgv/1234'
  NAMESPACE_IDENTIFIER = 'papyri.info'
  
  # Actual server address for the Numbers Server, could in theory be different from NAMESPACE_IDENTIFIER
  NUMBERS_SERVER_DOMAIN = 'papyri.info'
  NUMBERS_SERVER_PORT = 80

  class Timeout < ::Timeout::Error; end

  # Provides a number of class methods for working with identifiers and the Numbers Server  
  module NumbersHelper
    class << self
      # Converts e.g. 'papyri.info/hgv/1234' to '/hgv/1234'
      def identifier_to_local_identifier(identifier)
        identifier.sub(/^#{NAMESPACE_IDENTIFIER}/, '')
      end
      
      # Converts e.g. 'http://papyri.info/hgv/1234/rdf' to 'papyri.info/hgv/1234'
      def identifier_url_to_identifier(identifier)
        no_scheme = identifier.sub(/^http:\/\//,'')
        no_decorator = no_scheme.sub(/\/(rdf|source)$/,'')
      end
      
      # Splits identifier into component array by slashes 
      def identifier_to_components(identifier)
        if identifier.index(';')  # this is a DDbDP identifier
          i = identifier.rindex('/', identifier.index(';'))
          return identifier[0,i].split('/').push(identifier[i+1..-1])
        else
          return identifier.split('/')
        end
      end
      
      # Converts e.g. 'papyri.info/hgv/1234' to 'hgv/1234/source/rdf', where 'rdf' is the decorator.
      # Used by numbers_server_response methods to construct an appropriate HTTP request.
      def identifier_to_path(identifier, decorator)
        local_identifier = identifier_to_local_identifier(identifier)
        url_paths = identifier_to_components(local_identifier)
      	if ( identifier !~ /^papyri.info\/\w+$/ && decorator == "rdf")
          url_paths << "source"
      	end
        url_paths << decorator
        return url_paths.join('/')
      end
      
      # Converts a pure SPARQL query string into the appropriate URL path for our use. 
      def sparql_query_to_path(sparql_query)
        path = "/sparql?query=" + URI.escape(sparql_query)
        return path
      end
      
      # Converts e.g. 'papyri.info/hgv/1234' to 'http://papyri.info/hgv/1234'
      def identifier_to_url(identifier)
        if !identifier.blank? && identifier =~ /^#{NAMESPACE_IDENTIFIER}/
          return "http://#{identifier}"
        else
          return nil
        end
      end

      # Gets the HTTP response for a given URL path.
      def path_to_numbers_server_response(path, format = 'rdf')
        begin
          http = Net::HTTP.new(NUMBERS_SERVER_DOMAIN, NUMBERS_SERVER_PORT)
          headers = (format == 'json') ? {'Accept' => 'application/rdf+json'} : {}
          return http.get(path, headers)
        rescue ::Timeout::Error => e
          raise NumbersRDF::Timeout, e.message, caller
        end
      end
      
      # Gets the HTTP response for a given identifier. 
      def identifier_to_numbers_server_response(identifier, decorator = 'rdf')
        path = identifier_to_path(identifier, decorator)
        #puts "Path: #{path}"
        response = path_to_numbers_server_response(path, decorator)
      end
     
      # Gets the HTTP response for a given SPARQL query. 
      def sparql_query_to_numbers_server_response(sparql_query, format = '')
        path = sparql_query_to_path(sparql_query)
        response = path_to_numbers_server_response(path, format)
      end
     
      # Applies XPath to an HTTP response (assumed to be XML). 
      def apply_xpath_to_numbers_server_response(xpath, response)
        if response.code != '200'
          return nil
        else
          return process_numbers_server_response_body(
            response.body.force_encoding("UTF-8"),
            xpath)
        end
      end
      
      # Runs a SPARQL query and applies XPath to the response 
      def apply_xpath_to_sparql_query(xpath, sparql_query)
        response = sparql_query_to_numbers_server_response(sparql_query)
        apply_xpath_to_numbers_server_response(xpath, response)
      end
     
      # Performs a Numbers Server request on an identifier and applies XPath to the response 
      def apply_xpath_to_identifier(xpath, identifier, decorator = 'rdf')
        response = identifier_to_numbers_server_response(identifier, decorator)
        apply_xpath_to_numbers_server_response(xpath, response)
      end

      # Takes an identifier and returns an array of related identifiers from the numbers server.
      def identifier_to_identifiers(identifier)
        results = apply_xpath_to_identifier(
          "/rdf:RDF/rdf:Description[@rdf:about='http://#{identifier}/source']/dcterms:relation/@rdf:resource[not(. =//dcterms:replaces/@rdf:resource)]", identifier)
        if results.nil?
          return nil
        else
          return [identifier] + results.collect{|r| identifier_url_to_identifier(r)}
        end
      end
     
      # Gets the 'parts' for an identifier, useful for figuring out hierarchy coming in from an identifier class.
      # e.g. 'papyri.info/ddbdp' => ["papyri.info/ddbdp/bgu", "papyri.info/ddbdp/c.ep.lat", ...] 
      def identifier_to_parts(identifier)
        results = apply_xpath_to_identifier(
          "/rdf:RDF/rdf:Description[@rdf:about='http://#{identifier}']/dcterms:hasPart/@rdf:resource", identifier)
        if results.nil?
          return nil
        else
          return results.collect{|r| identifier_url_to_identifier(r)}
        end
      end
      
      # Turns e.g. 'papyri.info/hgv/P.Amh._2_48' into ['papyri.info/hgv/123', ...]
      def collection_identifier_to_identifiers(identifier)
        results = apply_xpath_to_sparql_query(
          "//*:uri/text()",
          'prefix dc: <http://purl.org/dc/terms/> select ?hgvid from <http://papyri.info/graph> where { ?hgvid dc:identifier <http://' + URI.escape(identifier) + '> . filter regex(str(?hgvid), "^http://papyri.info/hgv/")}'
        )
        if results.nil?
          return nil
        else
          return results.collect{|r| identifier_to_identifiers(identifier_url_to_identifier(r))}.flatten.uniq
        end
      end
      
      # Gets the title for an identifier using its frbr:Work/rdf representation.
      # Currently only works for HGV identifiers, e.g. 'papyri.info/hgv/25883/source' => 'P.Köln 3, 160 Einleitung'.
      def identifier_to_title(identifier)
        result = apply_xpath_to_identifier(
          "/rdf:RDF/rdf:Description/dcterms:bibliographicCitation/text()", identifier, 'work/rdf'
        )
        return result.nil? ? nil : result.first
      end

      # Takes an array of identifiers and
      # Returns a hash with IDENTIFIER_NAMESPACE (hgv, tm, ddbdp etc)  as the keys and the identifier as the value.
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
      
      # Applies XPath to an XML response body 
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
