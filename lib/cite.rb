module Cite
  require 'jruby_xml'
  require 'uuid'
  
  class CiteError < ::StandardError
  end
  
  CITE_JAR_PATH = File.join("#{Rails.root}", 'lib', *%w"java cite-0.12.22.jar")  
  GROOVY_JAR_PATH = File.join("#{Rails.root}", 'lib', *%w"java groovy-all-2.0.0-rc-3.jar")  
  NS_CITE = "http://chs.harvard.edu/xmlns/cite"

  OBJECT_TYPE_SEQUENCE = 'sequence'
  OBJECT_TYPE_UUID = 'uuid'

  module CiteLib
    
    class << self

      ######################################
      # Configuration Methods
      ######################################
      def get_config(a_key)
        unless defined? @config
          @config = YAML::load(ERB.new(File.new(File.join(Rails.root, %w{config cite.yml})).read).result)[Rails.env]
        end
        @config[a_key]
      end

      ######################################
      # Mock PITTypes API
      ######################################
      def pid(datatype, properties, sequencer_callback)
        config = get_config(datatype])
        if config.nil?
          raise Exception.new("Unknown datatype #{datatype}")
        end
        urn = config[:urn_template]
        if urn =~ /<property/
          properties.each do |key,value|
            urn = urn.gsub(/<property_#{key}>/,value)
          end
          if urn =~ /<property/
            raise Exception.new("Unable to complete urn template from properties #{urn}")
          end
        end
        case config[:object_type]
        when OBJECT_TYPE_SEQUENCE
          next_object_id = sequencer_callback(urn)
        when OBJECT_TYPE_UUID
          next_object_id = object_uuid_urn()
        else
          raise Exception.new("Unrecognized urn object type #{config[:object_type]}"
        end
        urn = urn + "." + next_object_id.to_s
        urn = add_version(urn)
        return urn
      end


      ######################################
      # CITE Collections API
      ######################################

      def getCapabilities
        # TODO Build up a Cite Inventory from the config
        # Perseids currnetly supports only a single type of Cite Collection, one which is made up of
        # a single Annotation string property.
      end

      ######################################
      # CITE URN Helper Methods
      ######################################

      # method which returns a CITE Urn object from the java chs cite library
      def urn_obj(a_urn)
        if(RUBY_PLATFORM == 'java')
          require 'java'
          require CITE_JAR_PATH
          require GROOVY_JAR_PATH
          java_import("edu.harvard.chs.cite.CiteUrn") { |pkg, name| "J" + name }
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
        begin 
          parts = a_urn.split(/:/)
          if (parts.length == 4)
           if parts[0] == 'urn' && parts[1] == 'cite' && parts[3] !~ /\./
               valid_collection_urn = true
           end 
          end
          # TODO - validate against inventory?
        rescue
          # if it's invalid, the answer is obviously false
        end
        return valid_collection_urn
      end
      
      # method to see if what we have is an object identifier
      def is_object_urn?(a_urn)
        valid_object_urn = false;
        parts = a_urn.split(/:/)
        if (parts.length == 4)
          obj_parts = parts[3].split(/\./)
          if parts[0] == 'urn' && parts[1] == 'cite' && obj_parts.length == 2 && obj_parts[1] !~ /\./
            valid_object_urn = true
          end 
        end
        # TODO - validate against inventory?
        return valid_object_urn
      end
      
      # method to see if what we have is a version identifier
      def is_version_urn?(a_urn)
        valid_version_urn = false;
        parts = a_urn.split(/:/)
        if (parts.length == 4)
          obj_parts = parts[3].split(/\./)
          if parts[0] == 'urn' && parts[1] == 'cite' && obj_parts.length == 3 
            valid_version_urn = true
          end 
        end
        # TODO - validate against inventory?
        return valid_version_urn
      end
      
      # return an object urn that assignes a uuid as the object id
      def object_uuid_urn(a_collection_urn)
        if (is_collection_urn?(a_collection_urn))
          return "#{a_collection_urn}.#{UUID.new.generate(:compact)}"
        else 
          raise "Invalid collection urn"
        end
      end

      # placeholder function for if/when we support versioning of CITE URN identified objects
      def add_version(a_urn)
        a_urn + ".1"
      end
    end # end class
  end # end module CiteLib
end # end Cite
