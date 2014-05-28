module Cite
  require 'jruby_xml'
  
  class CiteError < ::StandardError
  end
  
  CITE_JAR_PATH = File.join("#{RAILS_ROOT}", 'lib', *%w"java cite-0.12.22.jar")  
  GROOVY_JAR_PATH = File.join("#{RAILS_ROOT}", 'lib', *%w"java groovy-all-2.0.0-rc-3.jar")  
  NS_CITE = "http://chs.harvard.edu/xmlns/cite"
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
      
      # lookup the max size of a field (perseids extension of standard cite functionality)
      # only one restricted field allowed per collection
      def get_collection_field_max(a_urn)
        coll = get_collection(a_urn)
        field = coll.elements["*[@x-perseidsmax]"]
        if field.nil?
          # not defined - unlimited
          return -1
        else
          return field.attributes['x-perseidsmax'].to_i
        end
      end
      
      # lookup the collection in the Inventory and return the descriptive title
      def get_collection_title(a_urn)
        coll = get_collection(a_urn)
        if coll.nil?
          raise "Invalid Collection"
        else
           coll.attributes['description']
        end
      end
      
      def get_collection_urn(a_urn)
        urnObj = urn_obj(a_urn)
        urnObj.getNs() + ":" + urnObj.getCollection()
      end
      
      # lookup the collection in the Inventory
      def get_collection(a_urn)
        if (is_collection_urn?(a_urn))
          a_urn + a_urn + ".0.0"
        end
        urnObj = urn_obj(a_urn)
        name = urnObj.getCollection()
        ns = urnObj.getNs()
        xpath = "//cite:citeCollection[@name='#{name}' and cite:namespaceMapping[@abbr='#{ns}']]"
        return REXML::XPath.first(inventory(),xpath,{'cite' => NS_CITE})
      end
      
      # lookup the default collection in the Inventory
      def get_default_collection_urn()
        xpath = "//cite:citeCollection[@x-perseidsdefault='true']"
        coll = REXML::XPath.first(inventory(),xpath,{'cite' => NS_CITE})
        if (coll.nil?)
          return nil
        else
          ns = REXML::XPath.first(coll,"cite:namespaceMapping",{'cite' => NS_CITE})
          ns.attributes['abbr']
          "urn:cite:#{ns.attributes['abbr']}:#{coll.attributes['name']}"
        end
        
      end
      
      def inventory
        unless defined? @inventory
          @inventory = REXML::Document.new File.new(File.join("#{RAILS_ROOT}",'config','citecapabilities.xml'))
        end
        return @inventory
      end
      
      # Get the list of creatable identifiers for the supplied urn
      # @param {String} a_urn
      def get_creatable_identifiers(a_urn)
        
      end
    end # end class
  end # end module CiteLib
end # end Cite