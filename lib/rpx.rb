require 'uri'
require 'net/http'
require 'net/https'
require 'json'

module Rpx
  class RpxException < StandardError
    attr_reader :http_response

    def initialize(http_response)
      @http_response = http_response
    end
  end

  class RpxHelper
    attr_reader :api_key, :base_url, :realm

    def initialize(api_key, base_url, realm)
      @api_key = api_key
      @base_url = base_url.sub(/\/*$/, '')
      @realm = realm
    end

    def auth_info(token, token_url)
      data = api_call 'auth_info', :token => token, :tokenUrl => token_url
      data['profile']
    end

    def mappings(primary_key)
      data = api_call 'mappings', :primaryKey => primary_key
      data['identifiers']
    end

    def all_mappings
      data = api_call 'all_mappings'
      data['mappings']
    end

    def map(identifier, key)
      api_call 'map', :primaryKey => key, :identifier => identifier
    end

    def unmap(identifier, key)
      api_call 'unmap', :primaryKey => key, :identifier => identifier
    end

    def signin_url(dest, signin_method='signin')
      "#{rp_url}/openid/#{signin_method}?token_url=#{CGI.escape(dest)}"
    end

    private

    def rp_url
      parts = @base_url.split('://', 2)
      parts = parts.insert(1, '://' + @realm + '.')
      return parts.join('')
    end

    def api_call(method_name, partial_query = {})
      url = URI.parse("#{@base_url}/api/v2/#{method_name}")

      query = partial_query.dup
      query['format'] = 'json'
      query['apiKey'] = @api_key

      http = Net::HTTP.new(url.host, url.port)
      if url.scheme == 'https'
        http.use_ssl = true
      end

      data = query.map { |k,v|
        "#{CGI::escape k.to_s}=#{CGI::escape v.to_s}"
      }.join('&')

      resp = nil
      resp_body = ''
      begin
        resp = http.post(url.path, data)
        if resp.code != '200'
          raise RpxException.new(resp), "Unexpected HTTP status code from server: #{resp.code}: #{resp.body}"
        else
          resp_body = resp.body
        end
      rescue OpenSSL::SSL::SSLError => e
        Rails.logger.debug("OpenSSL::SSL::SSLError in RpxHelper#api_call, falling back to curl: #{e.inspect}")
        resp_body = `curl -s -X POST -d '#{data}' '#{url.to_s}'`
        unless $?.success?
          raise RpxException.new(resp), "Error in fallback curl command: #{$?.inspect}"
        end
      end

      begin
        data = JSON.parse(resp_body.force_encoding('UTF-8'))
      rescue JSON::ParserError => err
        raise RpxException.new(resp), 'Unable to parse JSON response'
      end

      if data['stat'] != 'ok'
        raise RpxException.new(resp), "Unexpected API error:\n  data: #{data.inspect}\n  resp: #{resp.inspect}"
      end

      return data
    end
  end

end
