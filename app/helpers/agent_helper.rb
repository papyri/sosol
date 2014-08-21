module AgentHelper

  # looks for the software agent in the data
  # TODO we need to decide upon a standardized approach to this
  
  def self.agent_of(a_data)
    unless defined? @agents
      @agents = YAML::load(ERB.new(File.new(File.join(RAILS_ROOT, %w{config agents.yml})).read).result)[:agents]
    end
    agent = nil
    @agents.keys.each do | a_agent |
      if (a_data =~ /#{@agents[a_agent][:uri_match]}/sm)
        agent = @agents[a_agent]
        break
      end
    end
    return agent
  end

end