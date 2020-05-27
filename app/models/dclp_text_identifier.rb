class DCLPTextIdentifier < DDBIdentifier
  attr_accessor :configuration, :valid_epidoc_attributes, :hybrid

  PATH_PREFIX = 'DCLP'

  FRIENDLY_NAME = "DCLP Text"
  IDENTIFIER_NAMESPACE = 'dclp'
  TEMPORARY_COLLECTION = 'SoSOL'
  XML_VALIDATOR = JRubyXML::DCLPEpiDocValidator
  
  # cl: at the moment there are no reprints for DCLP
  # therefore the result is always false
  # needs a proper implementation, though (one day)
  def is_reprinted?
    return false
  end

  # cl: CROMULENT DCLP ‘View in PN’ hack
  def get_catalog_link
    '/' + DCLPTextIdentifier::IDENTIFIER_NAMESPACE + '/' + self.name[/.+\/(\d+|SoSOL;\d{4};\d{4})$/, 1]
  end

  def self.collection_names_hash
    super.merge(TEMPORARY_COLLECTION => TEMPORARY_COLLECTION)
  end

  # Generates HTML preview for hgv metadata using EpiDoc transformation file *start-edition.xsl*
  # - *Args*  :
  #   - +parameters+ → xsl parameter hash, e.g. +{:leiden-style => 'ddb'}+, defaults to empty hash
  #   - +xsl+ → path to xsl file, relative to +Rails.root+, e.g. +%w{data xslt epidoc my.xsl})+, defaults to +data/xslt/epidoc/start-edition.xsl+
  # - *Returns* :
  #   - result of transformation operation as provided by +JRubyXML.apply_xsl_transform+
  def preview parameters = {}, xsl = nil
    parameters.reverse_merge!(
      "apparatus-style" => "ddbdp",
      "leiden-style" => "dclp"
    )
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(self.xml_content),
      JRubyXML.stream_from_file(File.join(Rails.root,
        xsl ? xsl : %w{data xslt epidoc start-edition.xsl})),
        parameters)
  end

  after_initialize :post_initialization_configuration
  # Loads +HgvMetaConfiguration+ object (HGV xpath for EpiDoc and options for the editor) and presets valid EpiDoc attributes
  # Side effect on +@configuration+ and + @valid_epidoc_attributes+
  def post_initialization_configuration
    @configuration = HgvMetaConfiguration.new #YAML::load_file(File.join(Rails.root, %w{config hgv.yml}))[:hgv][:metadata]
    @valid_epidoc_attributes = @configuration.keys
    @hybrid = get_hybrid :dclp
  end

  # ?
  def to_path
    if name =~ /#{self.class::TEMPORARY_COLLECTION}/
      return self.temporary_path
    else
      path_components = [ PATH_PREFIX ]
      # assume the name is e.g. hgv2302zzr
      trimmed_name = self.to_components.last # 2302zzr
      number = trimmed_name.sub(/\D/, '').to_i # 2302

      hgv_dir_number = ((number - 1) / 1000) + 1
      hgv_dir_name = "#{hgv_dir_number}"
      hgv_xml_path = trimmed_name + '.xml'

      path_components << hgv_dir_name << hgv_xml_path

      # e.g. HGV_meta_EpiDoc/HGV3/2302zzr.xml
      return File.join(path_components)
    end
  end

  # Path constructor for born-digital temporary SoSOL identifiers
  def temporary_path
    trimmed_name = name.sub(/(papyri|litpap).info\/#{IDENTIFIER_NAMESPACE}\//, '')
    components = trimmed_name.split(';')
    return File.join(self.class::PATH_PREFIX, components[0..-2], "#{components[-1]}.xml")
  end
  
  # ?
  def id_attribute
    return "dclpTEMP"
  end

  # ?
  def n_attribute
    text = DCLPTextIdentifier.find_by_publication_id(self.publication.id, :limit => 1)
    meta = DCLPMetaIdentifier.find_by_publication_id(self.publication.id, :limit => 1)

    return meta ? meta.n_attribute : (text ? text.n_attribute : nil)
  end
  
  def self.new_from_template(publication)
    DCLPMetaIdentifier.new_from_template(publication)
    return DCLPTextIdentifier.find_by_publication_id(publication.id)
  end

  # ?
  def xml_title_text
    return "Description of document"
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
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(content),
      JRubyXML.stream_from_file(File.join(Rails.root,
        %w{data xslt ddb preprocess.xsl})))
  end

  def self.new_from_dclp_meta_identifier(dclpMetaIdentifier)
    new_identifier = self.new(:name => dclpMetaIdentifier.name)

    Identifier.transaction do
      dclpMetaIdentifier.publication.lock!
      if dclpMetaIdentifier.publication.identifiers.select{|i| i.class == self}.length > 0
        return nil
      else
        new_identifier.publication = dclpMetaIdentifier.publication
        new_identifier.save!
      end
    end

    #initial_content = new_identifier.file_template
    #new_identifier.set_content(initial_content, :comment => 'Created from SoSOL template', :actor => (publication.owner.class == User) ? publication.owner.jgit_actor : publication.creator.jgit_actor)

    return new_identifier
  end

  # cl: CROMULENT DCLP ‘View in PN’ hack
  # name can be »papyri.info/dclp/SoSOL;2017;0002«
  def get_catalog_link
    '/' + DCLPMetaIdentifier::IDENTIFIER_NAMESPACE + '/' + self.name[/.+\/(\d+|SoSOL;\d{4};\d{4})$/, 1]
  end

  def correspondingDclpMetaIdentifier
    self.publication.controlled_identifiers.each {|i|
      if i.class == DCLPMetaIdentifier
        return i
      end
    }
  end

end
