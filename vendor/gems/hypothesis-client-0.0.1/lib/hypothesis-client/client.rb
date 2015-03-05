require 'json'
require 'uri'
require 'net/https'

module HypothesisClient

  class Client

    AGENT_URI = 'https://hypothes.is'
    FORMAT_OALD = 1 

    def initialize(mapper)
      @mapper = mapper
    end

    def get(a_uri,a_id=nil,a_owner=nil)
      respobj = {}
      begin
        uri = URI.parse(a_uri)
        id = uri.path.split(/\//).last
        uri.path = "/api/annotations/#{id}"
        http = Net::HTTP.new(uri.host, uri.port) 
        http.use_ssl = true
        headers = {'Accept' => 'application/json'}
        response = http.send_request('GET',uri.request_uri,nil,headers)
        if (response.code == '200') 
          respobj = { }
          orig_annot = JSON.parse(response.body)
          orig_annot[:sourceUri] = uri.to_s
          new_id = a_id.nil? ? a_uri : a_id
          mapped = map(new_id,orig_annot,a_owner)
          if (mapped[:errors].length > 0) 
            respobj[:is_error] = true
            respobj[:error] = mapped[:errors].join("\n")
          else 
            respobj[:data] = mapped[:data]
          end 
           
        else
          respobj = { :is_error  => true,
                      :error => "HTTP #{response.code}",
                    }
        end
      rescue => e
        respobj = { :is_error  => true,
                    :error => e.backtrace }
      end
      respobj
      
    end

    def map(id,data,owner=nil)
      @mapper.map(AGENT_URI,id,data,FORMAT_OALD,owner)
    end

  end

end

