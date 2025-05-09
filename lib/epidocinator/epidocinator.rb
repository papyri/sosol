# frozen_string_literal: true

require 'httpclient'
require 'nokogiri'
require 'stringio'

module Epidocinator
  class ParseError < ::StandardError
    attr_accessor :line, :column, :api_failure

    def initialize(api_failure = false, line = nil, column = nil)
      @api_failure = api_failure
      @line = line
      @column = column
    end

    def to_str
      # message can have XML elements in it that we want escaped
      # move to view?
      return "Error at line #{@line}, column #{@column}: #{CGI.escapeHTML(message)}" unless api_failure

      'An error occurred'
    end
  end

  class << self
    def validate(xml_document)
      epidocinator = EpidocinatorClient.new
      validation = epidocinator.validate_xml(xml_document)
      validation_json = JSON.parse(validation)
      return true if validation_json['result']

      errors = validation_json['errors'].first
      raise ParseError.new(false, errors['lineNumber'], errors['columnNumber']), errors['message']
    end

    def apply_xsl_transform(xml_stream, parameters)
      epidocinator = EpidocinatorClient.new
      transform = epidocinator.transform_xml(xml_stream, parameters)
      transform.force_encoding('UTF-8')
    end

    def apply_multipart_xsl_transform(xml_streams, parameters)
      epidocinator = EpidocinatorClient.new
      transform = epidocinator.transform_multipart_xml(xml_streams, parameters)
      transform.force_encoding('UTF-8')
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
    class EpidocinatorAPIRequestError < StandardError; end

    XML_CONTENT_HEADERS = { 'Content-Type' => 'text/xml; charset=UTF-8' }.freeze

    def initialize
      @client = HTTPClient.new
      @client.base_url = Sosol::Application.config.epidocinator.host[:url]
    end

    def validate_xml(xml_document)
      url = get_request_url('/relaxng', {})
      post(url, xml_document, XML_CONTENT_HEADERS)
    end

    def transform_multipart_xml(xml_streams, parameters = {})
      body = xml_streams.map do |stream|
        {
          :name => stream['name'],
          :filename => stream['name'],
          'Content-Disposition' => "form-data; name=\"#{stream['name']}\"; filename=\"#{stream['name']}\"",
          :content_type => 'text/xml; charset=UTF-8',
          :content => stream[:content]
        }
      end
      url = get_request_url('/transform', parameters)
      post(url, body, { 'Content-Type' => 'multipart/form-data' })
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
      Rails.logger.error "An error occurred proccessing Epidocinator API Request: #{error.message}"
      raise ParseError.new(true), 'Epidocinator API Failure'
    end
  end
end
