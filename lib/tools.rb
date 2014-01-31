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
      def tool_config(a_tool,as_json = false)
        unless defined? @config
          @config = YAML::load(ERB.new(File.new(File.join(RAILS_ROOT, %w{config tools.yml})).read).result)[Rails.env]
        end
        if (as_json)
         return @config[a_tool].to_json
        else
          return @config[a_tool]  
        end
      end
    end
  end
    
end