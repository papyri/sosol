# -*- coding: utf-8 -*-
class APISIdentifier < HGVMetaIdentifier
  attr_accessor :configuration, :valid_epidoc_attributes

  PATH_PREFIX = 'APIS'
  IDENTIFIER_NAMESPACE = 'apis'
  XML_VALIDATOR = JRubyXML::EpiDocP5Validator
  
  FRIENDLY_NAME = "APIS"

  def temporary_path
    # path constructor for born-digital temporary SoSOL identifiers
    trimmed_name = name.sub(/papyri.info\/apis\//, '')
    components = trimmed_name.split(';')
    return File.join(self.class::PATH_PREFIX, components[0..-2], "#{components[-1]}.xml")
  end

  def preview parameters = {}, xsl = nil
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(self.xml_content),
      JRubyXML.stream_from_file(File.join(RAILS_ROOT,
        xsl ? xsl : %w{data xslt epidoc start-edition.xsl})),
        parameters)
  end
  
  # Loads +ApisConfiguration+ object (APIS xpath for EpiDoc and options for the editor) and presets valid EpiDoc attributes
  # Side effect on +@configuration+ and + @valid_epidoc_attributes+
  def after_initialize
    @configuration = ApisConfiguration.new #YAML::load_file(File.join(RAILS_ROOT, %w{config apis.yml}))[:apis][:metadata]
    @valid_epidoc_attributes = @configuration.keys
  end

  def to_path
    if name =~ /#{self.class::TEMPORARY_COLLECTION}/
      return self.temporary_path
    else
      path_components = [ PATH_PREFIX ]
      trimmed_name = self.to_components.last
      collection = trimmed_name.sub(/\..*/, '')
      apis_xml_path = trimmed_name + '.xml'
      path_components << collection << "xml" << apis_xml_path
      # e.g. APIS/michigan/xml/michigan.apis.1.xml
      return File.join(path_components)
    end
  end

  def id_attribute
    return "apisTEMP"
  end

  def xml_title_text
    return "Description of document"
  end

  class ApisConfiguration

    attr_reader :scheme, :keys;

    def initialize
      @scheme = YAML::load_file(File.join(RAILS_ROOT, %w{config apis.yml}))[:apis][:metadata]

      add_meta_information! @scheme

      @keys = @scheme.keys
      @scheme.each_value {|item|
        @keys += retrieve_all_keys item
      }
  
    end

    # recursively retrieves all valid keys (element key, attribute keys, child keys)
    # configuration is a single element node of the hgv configuration
    def retrieve_all_keys configuration_node
      keys = configuration_node[:attributes] ? configuration_node[:attributes].keys : []
      if configuration_node[:children]
        configuration_node[:children].each_pair {|key, value|
          keys += [key]
          keys += retrieve_all_keys value
        }
      end
      return keys
    end

    # recursively adds optional attributes to configuration
    # parameter configuration is initially the complete apis configuration, during recursion it contains the content of the children attribute
    def add_meta_information! configuration
      configuration.each_value {|element|

        add_defaults! element

        if element.keys.include? :attributes
          element[:attributes].each_value{|attribute|
            add_defaults! attribute
          }
        end

        if element.keys.include? :children
          add_meta_information! element[:children]
        end

      }
    end

    # adds optional attributes (suchs as mulplicity or default value) to a configuration item
    # parameter item may be an element or an attribute
    def add_defaults! item
      if item.keys.include? :multiple
        item[:multiple] = item[:multiple] ? true : false
      else
        item[:multiple] = false
      end

      if item.keys.include? :optional
          item[:optional] = !item[:optional] ? false : true
      else
        item[:optional] = true
      end

      if !item.keys.include? :default
        item[:default] = nil
      end

      if !item.keys.include? :pattern
        item[:pattern] = nil
      end

      #if item.keys.include? :children
      #  item[:structure] = :recursive
      #elsif item[:multiple]
      #  item[:structure] = :multiple
      #else
      #  item[:structure] = :simple
      #end
    end

    def xpath key
      if @scheme.keys.include? key
        @scheme[key][:xpath]
      else
        ''
      end
    end

  end
end
