# frozen_string_literal: true

require 'httpclient'
require 'stringio'

module Epidocinator

  class << self
    # def initialize
    #   @epidocinator = EpidocinatorClient.new
    # end

    def validate_document(document)
      @epidocinator = EpidocinatorClient.new
      @epidocinator.process(document)
    end

    def apply_xsl_transform(xml_stream, parameters = {})
      @epidocinator = EpidocinatorClient.new
      @epidocinator.transform_xml(xml_stream, parameters)
    end
    
    def stream_from_string(input_string)
      StringIO.new(input_string)
    end

    def stream_from_file(input_file)
      File.open(input_file, 'r')
    end
  end

  class EpidocinatorClient

    class EpidocinatorHostError < StandardError; end
    class EpidocinatorAPIRequestError < StandardError; end

    def initialize
      # if Sosol::Application.config.respond_to?(:epidocinator_standalone_url)
      #   epidoc_host = Sosol::Application.config.epidocinator_standalone_url
      # else
      #   # throw no epidoc host error
      #   raise NoEpidocinatorHostError, 'No Epidocinator host URL provided'
      # end
      
      @client = HTTPClient.new
      @client.base_url = 'http://epidocinator:8085'
    end

    def transform_xml(xml_string, parameters)
      body = xml_string.string
      uri = URI(@client.base_url + '/transform')
      uri.query = URI.encode_www_form(parameters)
      res = post(uri.to_s, body, { 'Content-Type' => 'text/xml; charset=UTF-8'})
    end

    private

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
      begin
        response = yield
        unless response.status >= 200 && response.status < 300
          raise EpidocinatorAPIRequestError, "Request failed with status: #{response.status}, body: #{response.body}"
        end
        response.body
      rescue StandardError => e
        handle_error(e)
      end
    end

    def handle_error(error)
      # Log the error or handle it as needed
      Rails.logger.error "An error occurred: #{error.message}"
      raise EpidocinatorAPIRequestError, error.message
    end
  end
end