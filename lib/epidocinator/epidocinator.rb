# frozen_string_literal: true

require 'httpclient'
require 'nokogiri'
require 'stringio'

module Epidocinator
  class ParseError < ::StandardError
    attr_accessor :line, :column

    def initialize(line, column)
      @line = line
      @column = column
    end

    def to_str
      # message can have XML elements in it that we want escaped
      # move to view?
      "Error at line #{@line}, column #{@column}: #{CGI.escapeHTML(message)}"
    end
  end

  class << self
    def validate(xml_document)
      epidocinator = EpidocinatorClient.new
      epidocinator.validate_xml(xml_document)
    end

    def apply_xsl_transform(xml_stream, parameters)
      epidocinator = EpidocinatorClient.new
      epidocinator.transform_xml(xml_stream, parameters)
    end

    def stream_from_string(input_string)
      StringIO.new(input_string)
    end

    def stream_from_file(input_file)
      File.open(input_file, 'r')
    end

    def named_node_map_to_hash(attributes)
      return nil if attributes.nil? || attributes.empty?

      attributes.each_with_object({}) do |attr, result_hash|
        result_hash[attr.name] = attr.value
      end
    end

    def xpath_result_to_array(xpath_result)
      xpath_result.map do |node|
        if node.text? # Check if the node is a text node
          {
            name: "#text",
            value: node.text,
            attributes: named_node_map_to_hash(node.attributes)
          }
        else
          {
            name: "#{node.namespace&.prefix}:#{node.name}",
            value: node.value,
            attributes: named_node_map_to_hash(node.attributes)
          }
        end
      end
    end

    def apply_xpath(input_document_string, input_xpath_string, namespace_aware = false)
      doc = Nokogiri::XML(input_document_string)
      xpath_result = doc.xpath(input_xpath_string)
      xpath_result_to_array(xpath_result)
    end

  end

  class EpidocinatorClient
    class EpidocinatorHostError < StandardError; end
    class EpidocinatorAPIRequestError < StandardError; end

    XML_CONTENT_HEADERS = { 'Content-Type' => 'text/xml; charset=UTF-8' }.freeze

    def initialize
      # if Sosol::Application.config.respond_to?(:epidocinator_standalone_url)
      #   epidoc_host = Sosol::Application.config.epidocinator_standalone_url
      # else
      #   # throw no epidoc host error
      #   raise NoEpidocinatorHostError, 'No Epidocinator host URL provided'
      # end

      @client = HTTPClient.new
      @client.base_url = Sosol::Application.config.epidocinator.host[:url]
    end

    def validate_xml(xml_document)
      url = get_request_url('/relaxng', {})
      post(url, xml_document, XML_CONTENT_HEADERS)
    end

    def transform_xml(xml_string, parameters = {})
      body = xml_string.string
      url = get_request_url('/transform', parameters)
      post(url, body, XML_CONTENT_HEADERS)
    end

    private

    def get_request_url(path, parameters)
      uri = URI(@client.base_url + path)
      uri.query = URI.encode_www_form(parameters)
      uri.to_s
    end

    def get(url, headers = {})
      execute_request { @client.get(url, nil, headers) }
    end

    def post(url, body = {}, headers = {})
      execute_request { @client.post(url, body, headers) }
    end

    def put(url, body = {}, headers = {})
      execute_request { @client.put(url, body, headers) }
    end

    def delete(url, headers = {})
      execute_request { @client.delete(url, nil, headers) }
    end

    def execute_request
      response = yield
      unless response.status >= 200 && response.status < 300
        raise EpidocinatorAPIRequestError, "Request failed with status: #{response.status}, body: #{response.body}"
      end

      response.body
    rescue StandardError => e
      handle_error(e)
    end

    def handle_error(error)
      # Log the error or handle it as needed
      Rails.logger.error "An error occurred: #{error.message}"
      raise EpidocinatorAPIRequestError, error.message
    end
  end
end
