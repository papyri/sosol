module Tools
  
  # An Exception caused by misconfiguration of the tool
  class ConfigurationError < ::StandardError
  end
  
  # An Exception indicating HTTP request returned a failure code
  class RequestFailedError < ::StandardError
  end
  
  module Manager
    class << self
      # Retrieves the configuration for a specific tool from the tools.yml
      # @param [String] a_svc the service name
      def tool_config(a_type,as_json = false)
        unless defined? @config
          @config = YAML::load(ERB.new(File.new(File.join(RAILS_ROOT, %w{config tools.yml})).read).result)[Rails.env]
        end
        if (as_json)
          return @config[a_type].to_json
        else
          return @config[a_type]  
        end
      end
      
      def tool_for_agent(a_type,a_uri)
        tools = tool_config(a_type).keys.each.select { |a_tool| @config[a_type][a_tool][:uri] == a_uri }
        return tools.size > 0 ? tools[0] : nil
      end
      
      def link_to(a_type,a_tool,a_action,a_identifiers=[])
        config = tool_config(a_type)[a_tool]
        link = nil
        if (config && config[:actions][a_action])
          link = {}
          link[:href] = config[:actions][a_action][:href]
          id_param = config[:actions][a_action][:id_param]
          if (id_param)
            a_identifiers.each do | id | 
              link[:href] = link[:href] + "&" + id_param + "=" + id.id.to_s
            end
          end
          link[:target] = config[:actions][a_action][:target] || config[:target]
          link[:text] = config[:actions][a_action][:text] || config[:text]
          link[:replace_param] = config[:actions][a_action][:replace_param]
        end 
        return link
      end
      
       def link_all(a_type,a_action,a_identifiers=[],a_query=nil)
        links = []
        tool_config(a_type).keys.each do | a_tool |
          link = link_to(a_type,a_tool,a_action,a_identifiers)
          links << link
        end 
        return links
      end
    end
  end
    
end
