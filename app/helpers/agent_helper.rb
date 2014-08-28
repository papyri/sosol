require 'mediawiki_api'
module AgentHelper

  # looks for the software agent in the data
  # TODO we need to decide upon a standardized approach to this

  def self.get_agents
    unless defined? @agents
      @agents = YAML::load(ERB.new(File.new(File.join(RAILS_ROOT, %w{config agents.yml})).read).result)[:agents]
    end
    @agents
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

  def self.get_client(a_agent)
    if (a_agent.nil?)
       return nil
    end
    if (a_agent[:type] == 'mediawiki')
        return MediaWikiAgent.new(a_agent[:api_info])
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
      params = { :format => @conf[:data_format], :ids => a_uri, :token_type => false }
      @client.action("wbgetentities",params).data
    end

    def post_content(a_uri,a_content,a_format)
#      @client.prop :info, titles: a_page
#     @client.query titles: [a_page]
#     @client.create_page a_page, a_content
    end

  end

end
