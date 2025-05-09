class DCLPTextIdentifier < DDBIdentifier
  attr_accessor :configuration, :valid_epidoc_attributes, :hybrid

  PATH_PREFIX = 'DCLP'.freeze

  FRIENDLY_NAME = 'DCLP Text'.freeze
  IDENTIFIER_NAMESPACE = 'dclp'.freeze
  TEMPORARY_COLLECTION = 'SoSOL'.freeze

  # cl: at the moment there are no reprints for DCLP
  # therefore the result is always false
  # needs a proper implementation, though (one day)
  def is_reprinted?
    false
  end

  # cl: CROMULENT DCLP ‘View in PN’ hack
  def get_catalog_link
    "/#{DCLPTextIdentifier::IDENTIFIER_NAMESPACE}/#{name[%r{.+/(\d+[a-z]*|SoSOL;\d{4};\d{4})$}, 1]}"
  end

  def self.collection_names_hash
    super.merge(TEMPORARY_COLLECTION => TEMPORARY_COLLECTION)
  end

  # Generates HTML preview for hgv metadata using EpiDoc transformation file *start-edition.xsl*
  # - *Args*  :
  #   - +parameters+ → xsl parameter hash, e.g. +{:leiden-style => 'ddb'}+, defaults to empty hash
  #   - +xsl+ → path to xsl file, relative to +Rails.root+, e.g. +%w{data xslt epidoc my.xsl})+, defaults to +data/xslt/epidoc/start-edition.xsl+
  # - *Returns* :
  #   - result of transformation operation as provided by +Epidocinator.apply_xsl_transform+
  def preview(parameters = {}, xsl = nil)
    Epidocinator.apply_xsl_transform(
      Epidocinator.stream_from_string(xml_content),
      {
        # MakeFragment.xsl does not have a template for dclp
        'xsl' => 'previewddb',
        'collection' => 'ddbdp',
        'apparatus-style' => 'ddbdp',
        'internal-app-style' => 'ddbdp',
        'leiden-style' => 'ddbdp'
      }
    )
  end

  after_initialize :post_initialization_configuration
  # Loads +HGVMetaConfiguration+ object (HGV xpath for EpiDoc and options for the editor) and presets valid EpiDoc attributes
  # Side effect on +@configuration+ and + @valid_epidoc_attributes+
  def post_initialization_configuration
    @configuration = HGVMetaConfiguration.new # YAML::load_file(File.join(Rails.root, %w{config hgv.yml}))[:hgv][:metadata]
    @valid_epidoc_attributes = @configuration.keys
    @hybrid = get_hybrid :dclp
  end

  # ?
  def to_path
    if /#{self.class::TEMPORARY_COLLECTION}/.match?(name)
      temporary_path
    else
      path_components = [PATH_PREFIX]
      # assume the name is e.g. hgv2302zzr
      trimmed_name = to_components.last # 2302zzr
      number = trimmed_name.sub(/\D/, '').to_i # 2302

      hgv_dir_number = ((number - 1) / 1000) + 1
      hgv_dir_name = hgv_dir_number.to_s
      hgv_xml_path = "#{trimmed_name}.xml"

      path_components << hgv_dir_name << hgv_xml_path

      # e.g. HGV_meta_EpiDoc/HGV3/2302zzr.xml
      File.join(path_components)
    end
  end

  # Path constructor for born-digital temporary SoSOL identifiers
  def temporary_path
    trimmed_name = name.sub(%r{(papyri|litpap).info/#{IDENTIFIER_NAMESPACE}/}, '')
    components = trimmed_name.split(';')
    File.join(self.class::PATH_PREFIX, components[0..-2], "#{components[-1]}.xml")
  end

  # ?
  def id_attribute
    'dclpTEMP'
  end

  # ?
  def n_attribute
    text = DCLPTextIdentifier.find_by(publication_id: publication.id)
    meta = DCLPMetaIdentifier.find_by(publication_id: publication.id)

    if meta
      meta.n_attribute
    else
      (text ? text.n_attribute : nil)
    end
  end

  def self.new_from_template(publication)
    DCLPMetaIdentifier.new_from_template(publication)
    DCLPTextIdentifier.find_by(publication_id: publication.id)
  end

  # ?
  def xml_title_text
    'Description of document'
  end

  # Place any actions you always want to perform on HGV Meta identifier content prior to it being committed in this method
  # - *Args*  :
  #   - +content+ -> HGVMetaIdentifier XML as string
  def before_commit(content)
    DCLPTextIdentifier.preprocess(content)
  end

  # Applies the preprocess XSLT to 'content'
  # - *Args*  :
  #   - +content+ -> XML as string
  # - *Returns* :
  #   - modified 'content'
  def self.preprocess(content)
    Epidocinator.apply_xsl_transform(
      Epidocinator.stream_from_string(content),
      {
        'xsl' => 'preprocess'
      }
    )
  end

  def self.new_from_dclp_meta_identifier(dclpMetaIdentifier)
    new_identifier = new(name: dclpMetaIdentifier.name)

    Identifier.transaction do
      dclpMetaIdentifier.publication.lock!
      if dclpMetaIdentifier.publication.identifiers.count { |i| i.instance_of?(self) }.positive?
        return nil
      else
        new_identifier.publication = dclpMetaIdentifier.publication
        new_identifier.save!
      end
    end

    # initial_content = new_identifier.file_template
    # new_identifier.set_content(initial_content, :comment => 'Created from SoSOL template', :actor => (publication.owner.class == User) ? publication.owner.jgit_actor : publication.creator.jgit_actor)

    new_identifier
  end

  def correspondingDCLPMetaIdentifier
    publication.controlled_identifiers.each do |i|
      return i if i.instance_of?(DCLPMetaIdentifier)
    end
  end
end
