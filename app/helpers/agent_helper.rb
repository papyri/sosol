require 'mediawiki_api'
require 'hypothesis-client'
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
      if (a_data =~ /#{agents[a_agent][:uri_match]}/sm)
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
    else
      raise "Agent type #{a_agent[:type]} not supported"
    end
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
      @client.action("wbgetentities",params).data
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
                 :claim => parsed['claim'].to_json }
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
end
