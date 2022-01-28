class APISIdentifier < HGVMetaIdentifier
  attr_accessor :configuration, :valid_epidoc_attributes

  PATH_PREFIX = 'APIS'.freeze
  IDENTIFIER_NAMESPACE = 'apis'.freeze
  XML_VALIDATOR = JRubyXML::APISEpiDocValidator
  FRIENDLY_NAME = 'APIS'.freeze

  def temporary_path
    # path constructor for born-digital temporary SoSOL identifiers
    trimmed_name = name.sub(%r{papyri.info/apis/}, '')
    components = trimmed_name.split(';')
    File.join(self.class::PATH_PREFIX, components[0..-2], "#{components[-1]}.xml")
  end

  def preview(parameters = {}, xsl = nil)
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(xml_content),
      JRubyXML.stream_from_file(File.join(Rails.root,
                                          xsl || %w[data xslt epidoc start-edition.xsl])),
      parameters
    )
  end

  after_initialize :post_initialization_configuration
  # Loads +ApisConfiguration+ object (APIS xpath for EpiDoc and options for the editor) and presets valid EpiDoc attributes
  # Side effect on +@configuration+ and + @valid_epidoc_attributes+
  def post_initialization_configuration
    @configuration = ApisConfiguration.new # YAML::load_file(File.join(Rails.root, %w{config apis.yml}))[:apis][:metadata]
    @valid_epidoc_attributes = @configuration.keys
  end

  # Creates a hash of the names of all the APIS Collections available in SoSOL
  # Overrides method in Identifier
  # - used in selector
  def self.collection_names_hash
    collection_names

    unless defined? @collection_names_hash
      @collection_names_hash = {}
      @collection_names.each do |collection_name|
        @collection_names_hash[collection_name] = collection_name
      end
    end

    @collection_names_hash
  end

  # Determines the next 'SoSOL' temporary name for the associated identifier
  # This overrides the identifier superclass definition so that SoSOL-side APIS
  # id's will be e.g. papyri.info/apis/yale.apis.2011-0001 instead of papyri.info/apis/SoSOL;2011;0001
  # - starts at '1' each year
  # - *Returns* :
  #   - temporary identifier name
  def self.next_temporary_identifier(apis_collection)
    year = Time.zone.now.year
    latest = where('name like ?',
                   "papyri.info/#{self::IDENTIFIER_NAMESPACE}/#{apis_collection}.apis.#{year}-%").order(name: :desc).limit(1).first
    document_number = if latest.nil?
                        # no constructed id's for this year/class
                        1
                      else
                        latest.to_components.last.split(';').last.to_i + 1
                      end

    format("papyri.info/#{self::IDENTIFIER_NAMESPACE}/#{apis_collection}.apis.%04d-%04d",
           year, document_number)
  end

  # Create default XML file and identifier model entry for associated identifier class
  # - *Args*  :
  #   - +publication+ -> the publication the new translation is a part of
  # - *Returns* :
  #   - new identifier
  def self.new_from_template(publication, collection = 'unknown')
    new_identifier = new(name: next_temporary_identifier(collection))
    Identifier.transaction do
      publication.lock!
      if publication.identifiers.select { |i| i.instance_of?(self) }.length.positive?
        return nil
      else
        new_identifier.publication = publication
        new_identifier.save!
      end
    end

    initial_content = new_identifier.file_template
    new_identifier.set_content(initial_content, comment: 'Created from SoSOL template',
                                                actor: publication.owner.instance_of?(User) ? publication.owner.jgit_actor : publication.creator.jgit_actor)

    new_identifier
  end

  def to_path
    if name =~ /#{self.class::TEMPORARY_COLLECTION}/
      temporary_path
    else
      path_components = [PATH_PREFIX]
      trimmed_name = to_components.last
      collection = trimmed_name.sub(/\..*/, '')
      apis_xml_path = "#{trimmed_name}.xml"
      path_components << collection << 'xml' << apis_xml_path
      # e.g. APIS/michigan/xml/michigan.apis.1.xml
      File.join(path_components)
    end
  end

  def id_attribute
    'apisTEMP'
  end

  def n_attribute
    nil
  end

  def xml_title_text
    'Description of document'
  end

  class ApisConfiguration
    attr_reader :scheme, :keys

    def initialize
      @scheme = YAML.load_file(File.join(Rails.root, %w[config apis.yml]))[:apis][:metadata]

      add_meta_information! @scheme

      @keys = @scheme.keys
      @scheme.each_value do |item|
        @keys += retrieve_all_keys item
      end
    end

    # recursively retrieves all valid keys (element key, attribute keys, child keys)
    # configuration is a single element node of the hgv configuration
    def retrieve_all_keys(configuration_node)
      keys = configuration_node[:attributes] ? configuration_node[:attributes].keys : []
      configuration_node[:children]&.each_pair do |key, value|
        keys += [key]
        keys += retrieve_all_keys value
      end
      keys
    end

    # recursively adds optional attributes to configuration
    # parameter configuration is initially the complete apis configuration, during recursion it contains the content of the children attribute
    def add_meta_information!(configuration)
      configuration.each_value do |element|
        add_defaults! element

        if element.keys.include? :attributes
          element[:attributes].each_value do |attribute|
            add_defaults! attribute
          end
        end

        add_meta_information! element[:children] if element.keys.include? :children
      end
    end

    # adds optional attributes (suchs as mulplicity or default value) to a configuration item
    # parameter item may be an element or an attribute
    def add_defaults!(item)
      item[:multiple] = if item.keys.include? :multiple
                          item[:multiple] ? true : false
                        else
                          false
                        end

      item[:optional] = if item.keys.include? :optional
                          item[:optional] ? true : false
                        else
                          true
                        end

      item[:default] = nil unless item.keys.include? :default

      item[:pattern] = nil unless item.keys.include? :pattern

      # if item.keys.include? :children
      #  item[:structure] = :recursive
      # elsif item[:multiple]
      #  item[:structure] = :multiple
      # else
      #  item[:structure] = :simple
      # end
    end

    def xpath(key)
      if @scheme.keys.include? key
        @scheme[key][:xpath]
      else
        ''
      end
    end
  end
end
