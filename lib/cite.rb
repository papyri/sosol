module Cite
  require 'jruby_xml'
  
  CITE_JAR_PATH = File.join("#{RAILS_ROOT}", 'lib', *%w"java cite-0.12.22.jar")  
  GROOVY_JAR_PATH = File.join("#{RAILS_ROOT}", 'lib', *%w"java groovy-all-2.0.0-rc-3.jar")  
  module CiteLib 
    class << self
      # method which returns a CITE Urn object from the java chs cite library
      def urn_obj(a_urn)
        if(RUBY_PLATFORM == 'java')
          require 'java'
          require CITE_JAR_PATH
          require GROOVY_JAR_PATH
          include_class("edu.harvard.chs.cite.CiteUrn") { |pkg, name| "J" + name }
          urn = JCiteUrn.new(a_urn)
        else
          require 'rubygems'
          require 'rjb'
          Rjb::load(classpath = ".:#{CITE_JAR_PATH}:#{GROOVY_JAR_PATH}", jvmargs=[])
          cite_urn_class = Rjb::import('edu.harvard.chs.cite.CiteUrn')
          urn = cite_urn_class.new(a_urn)
        end
        return urn
      end
      
      # method to see if all we have is a collection identifier
      def is_collection_urn?(a_urn)
        valid_collection_urn = false;
        parts = a_urn.split(/:/)
        if (parts.length == 4)
         if parts[0] == 'urn' && parts[1] == 'cite' && parts[3] !~ /\./
             valid_collection_urn = true
         end 
        end
        return valid_collection_urn
      end
    end
    
    
  end
end