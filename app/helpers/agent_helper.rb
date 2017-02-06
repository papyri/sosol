#encoding UTF-8
require 'mediawiki_api'
require 'hypothesis-client'
require 'base64'
require 'openssl'
module AgentHelper

  # looks for the software agent in the data
  # TODO we need to decide upon a standardized approach to this

  def self.get_agents
    unless defined? @agents
      @agents = YAML::load(ERB.new(File.new(File.join(Rails.root, %w{config agents.yml})).read).result)[:agents]
    end
    @agents
  end

  def self.agents_can_convert()
    can_convert = []
    agents = get_agents()
    agents.keys.each do | a_agent |
      if agents[a_agent][:data_mapper]
        can_convert << agents[a_agent][:uri_match];
      end
    end
    can_convert
  end
  
  def self.agent_of(a_data)
    agent = nil
    agents = get_agents()
    agents.keys.each do | a_agent |
      if (a_data =~ /#{agents[a_agent][:uri_match]}/m)
        agent = agents[a_agent]
        break
      end
    end
    return agent
  end

  def self.get_target_collection(a_agent,a_type)
    if (a_agent.nil? || a_agent[:collections].nil?)
       return nil
    end
    a_agent[:collections][a_type]
  end

  def self.get_client(a_agent)
    if (a_agent.nil?)
       return nil
    end
    if (a_agent[:type] == 'mediawiki')
        return MediaWikiAgent.new(a_agent[:api_info])
    elsif (a_agent[:type] == 'hypothesis')
        return HypothesisAgent.new(a_agent[:data_mapper])
    elsif (a_agent[:type] == 'googless')
        return GoogleSSAgent.new(a_agent)
    elsif (a_agent[:type] == 'cts')
        return CtsAgent.new(a_agent)
    elsif (a_agent[:type] == 'url')
        return UrlAgent.new()
    elsif (a_agent[:type] == 'github')
        return GitHubProxyAgent.new(a_agent)
    elsif (a_agent[:type] == 'srophe_processor')
        return SropheProcessorAgent.new(a_agent)
    else
      raise "Agent type #{a_agent[:type]} not supported"
    end
  end

  # retrieve content for this identifier from an external agent (or agents)
  # @param {Array} a_init_urls array of potential agent urls - only the
  #                first valid agent url is used
  # @returns the content as a string
  def self.content_from_agent(a_init_urls,a_model_class,a_transform_params = {})
    agent = nil
    agent_url = nil
    a_init_urls.each do | a_url |
      agent = self.agent_of(a_url)
      if (agent)
        agent_url = a_url
        break;
      end
    end
    if agent.nil?
      raise "Agent not found for #{a_init_urls.join " "}"
    end

    agent_client = self.get_client(agent)
    raw_content = agent_client.get_content(agent_url) 
    a_transform_params[:e_agentUri] = agent[:uri_match]
    transform = agent_client.get_transformation(a_model_class)
    content = JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(raw_content),
      JRubyXML.stream_from_file(File.join(Rails.root,transform)),
        a_transform_params
    )  
    return content
  end

  class MediaWikiAgent 
    attr_accessor :conf, :client

    def initialize(a_conf)
      @conf = a_conf 
      @client = MediawikiApi::Client.new @conf[:url]
      @client.log_in @conf[:auth][:username], @conf[:auth][:password]
    end

    def get_content(a_uri)
      params = { :format => @conf[:data_format][:get], :ids => a_uri, :token_type => false }
      @client.action("wbgetentities",params).data.force_encoding("utf-8")
    end

    def post_content(a_content)
      begin
        parsed = JSON.parse(a_content)
      rescue Exception => a_e
        Rails.logger.error(a_e)
        Rails.logger.error(a_e.backtrace)
        raise "Error parsing content for agent submission"
      end
      # first we need to create a new claim
      params = { :entity => parsed['id'],
                 :token_type => 'edit',
                 :baserevid => parsed['lastrevid'],
                 :property => parsed['claim']['mainsnak']['property'],
                 :snaktype => 'somevalue'
               }
      begin
        created = @client.action("wbcreateclaim",params).data
      rescue Exception => a_e
        Rails.logger.error(a_e)
        Rails.logger.error(a_e.backtrace)
        raise "Error creating new mediawiki claim from submission"
      end 
      unless (created['claim']['id'])
        raise "Unable to parse id from newly created claim"
        Rails.logger.error("No id found in #{created.inspect}")
      end
      begin
        parsed['claim']['id'] = created['claim']['id']
        setp = { :token_type => 'edit',
                 :baserevid => created['pageinfo']['lastrevid'],
                 :claim => JSON.generate(parsed['claim']) }
        @client.action("wbsetclaim",setp).data
      rescue Exception => a_e
        Rails.logger.error(a_e)
        Rails.logger.error(a_e.backtrace)
        remp = { :token_type => 'edit',
                 :summary => 'cleaning up from failed update',
                 :claim => created['claim']['id'] }
        @client.action("wbremoveclaims",remp).data
        # we need to remove the newly created but empty claim
      end
    end
  end

  class CtsAgent
    attr_accessor :conf, :client
    def initialize(a_conf)
      @conf = a_conf 
    end
    def get_content(a_uri)
      url = @conf[:get_url].sub(/URN/,a_uri)
      url = URI.parse(url)
      response = Net::HTTP.start(url.host, url.port) do |http|
        http.send_request('GET',url.request_uri)
      end
      unless (response.code == '200')
        raise "Unable to retrieve content from #{url}"
      end
      return response.body.force_encoding("UTF-8")
    end
    def get_transformation(a_identifiertype)
      if (@conf[:transformations])
        @conf[:transformations][a_identifiertype]
      else
        nil
      end
    end
  end

  class HypothesisAgent
    attr_accessor :conf, :client

    def initialize(a_mapper)
      mapper_class = a_mapper.constantize
      @client = HypothesisClient::Client.new(mapper_class.new)
    end

    def get_content(a_uri,a_id,a_user)
      @client.get(a_uri,a_id,a_user)
    end
  end

  # A generic agent for retrieving content from a URL
  class UrlAgent
    def get_content(a_uri)
      if (a_uri =~ /^https?/)
        conn = Faraday.new(a_uri) do |c|
          c.use Faraday::Response::Logger, Rails.logger
          c.use FaradayMiddleware::FollowRedirects, limit: 3
          c.use Faraday::Response::RaiseError
          c.use Faraday::Adapter::NetHttp
        end
        conn.get.body.force_encoding("UTF-8")
      else
        raise "Invalid URL #{a_uri}"
      end
    end
  end

  class GoogleSSAgent
    attr_accessor :conf
    def initialize(a_conf)
      @conf = a_conf 
    end

    def get_content(a_url)
      # temporary hack -- we should use google apis for google drive 
      # integration and configure google as a full fledged agent
      worksheet_idmatch = nil
      # TODO This nonsense should be replaced by use of google api
      worksheet_idmatch = a_url.match(/key=([^&;\s]+)/) || # old style url
        a_url.match(/\/([^\/]+)\/(pubhtml|edit)/) # newer url
      unless worksheet_idmatch 
        raise "Invalid URL: Unable to parse spreadsheet id from #{a_url}"
      end
      worksheet_id = worksheet_idmatch.captures[0] 
      uri = @conf[:get_url].sub(/WORKSHEET_ID/,worksheet_id)
      uri = URI.parse(uri)
      response = Net::HTTP.start(uri.host, uri.port) do |http|
        http.send_request('GET',uri.request_uri)
      end
      unless (response.code == '200')
        raise "Unable to retrieve content from #{uri}"
      end
      return response.body.force_encoding("UTF-8")
    end

    def get_transformation(a_identifiertype)
      if (@conf[:transformations])
        @conf[:transformations][a_identifiertype]
      else
        nil
      end
    end
  end

  class GitHubProxyAgent
    attr_accessor :conf
    def initialize(a_conf)
      @conf = a_conf
    end

    def post_content(identifier,a_content)
        encoded = Base64.encode64(a_content)
        path = identifier.respond_to?(:to_remote_path) ? identifier.to_remote_path : identifier.to_path
        params = {}
        params['author_name'] = identifier.publication.creator.name
        params['author_email'] = identifier.publication.creator.email
        params['date'] = Time.now.xmlschema
        params['logs'] = @conf[:log_message].sub('<USER>',identifier.publication.creator.human_name).sub('<ID>',identifier.id_attribute)
        params['branch'] = identifier.repository.name + "/" + identifier.branch
        # params['callback_url'] = ....
        url = @conf[:post_url].sub('<PATH>',path)
        url = url + "?" unless url =~ /\?$/
        params.each do |k,v|
          url = url + "&#{k}=#{CGI.escape(v)}"
        end
        url = URI.parse(url)

        #hmac = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), @conf[:client_secret], encoded+@conf[:client_secret]).strip()
        sha = Digest::SHA256.hexdigest(encoded + @conf[:client_secret])
        response = Net::HTTP.start(url.host, url.port) do |http|
          headers = {'Content-Type' => 'text/xml; charset=utf-8',
                     'Content-Transfer-Encoding' => 'BASE64',
                     'fproxy-secure-hash' => sha}
          if (@conf[:timeout])
            http.read_timeout = conf[:timeout]
          end
          http.send_request('POST',url.request_uri,encoded,headers)
        end
        if (response.code != '201')
          raise Exception.new("Received error response #{response.code} #{response.msg} POSTING to #{url.request_uri}")
        end
    end
    def get_transformation(a_identifiertype)
      if (@conf[:transformations])
        @conf[:transformations][a_identifiertype]
      else
        nil
      end
    end
  end

  class SropheProcessorAgent
    attr_accessor :conf
    def initialize(a_conf)
      @conf = a_conf
    end

    def post_content(content)
      url = URI.parse(@conf[:post_url])
      response = Net::HTTP.start(url.host, url.port) do |http|
        headers = {'Content-Type' => 'text/xml; charset=utf-8',
                   'apikey' => @conf[:apikey]}
        if (@conf[:timeout])
          http.read_timeout = conf[:timeout]
        end
        http.send_request('POST',url.request_uri,content,headers)
      end
      if (response.code != '200')
        error = "Received error response #{response.code} #{response.msg} POSTING to #{url.request_uri}"
        Rails.logger.error(error)
        raise Exception.new(error)
      else
        new_content = response.body.force_encoding("UTF-8")
        parser = XmlHelper::getDomParser(new_content,'REXML')
        doc = parser.parseroot
        tei = parser.first(doc, "/response[@status='okay']/record/tei:TEI", {'tei' => "http://www.tei-c.org/ns/1.0"})
        return tei.to_s
      end
    end
    
    def to_s
      @conf[:post_url]
    end
  end
end
