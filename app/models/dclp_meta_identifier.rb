class DCLPMetaIdentifier < HGVMetaIdentifier
  attr_accessor :hybrid

  PATH_PREFIX = 'DCLP'.freeze

  FRIENDLY_NAME = 'DCLP Meta'.freeze
  IDENTIFIER_NAMESPACE = 'dclp'.freeze

  XML_VALIDATOR = JRubyXML::DCLPEpiDocValidator

  # cl: needs to load additional xpaths
  # Loads +HgvMetaConfiguration+ object (HGV xpath for EpiDoc and options for the editor) and presets valid EpiDoc attributes
  # Side effect on +@configuration+ and + @valid_epidoc_attributes+
  def post_initialization_configuration
    @configuration = HgvMetaIdentifierHelper::HgvMetaConfiguration.new :dclp
    @valid_epidoc_attributes = @configuration.keys
    @hybrid = get_hybrid :dclp
  end

  # cl: can be made simpler for DCLP needs
  def to_path
    if /#{self.class::TEMPORARY_COLLECTION}/o.match?(nameo)
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

  # cl: load DCLP text here?
  def n_attribute
    nil
  end

  # cl: does dclp have other needs in terms of preprocessing the data
  # Place any actions you always want to perform on HGV Meta identifier content prior to it being committed in this method
  # - *Args*  :
  #   - +content+ -> HGVMetaIdentifier XML as string
  def before_commit(content)
    DCLPMetaIdentifier.preprocess(content)
  end

  # Whenever a DCLP Meta Identifier is renamed, the corresponding DCLP Text Identifier needs to be renamed as well
  def after_rename(options = {})
    super(options)
    publication.controlled_identifiers.each do |i|
      next unless i.instance_of?(DCLPTextIdentifier) && i.name != options[:new_name]

      i.transaction do
        relatives = i.relatives
        i.name = options[:new_name]
        i.title = i.titleize
        i.save!
        relatives.each do |relative|
          relative.name = i.name
          relative.title = i.title
          relative.save!
        end
      end
    end
  end

  def self.new_from_template(publication)
    dclp_meta = super
    DCLPTextIdentifier.new_from_dclp_meta_identifier(dclp_meta) unless dclp_meta.nil?
    dclp_meta
  end

  def to_string
    serialization_string = ''
    @configuration.scheme.each_key do |key|
      serialization_string += "__#{key}__: #{self[key]}"
    end
    serialization_string
  end

  # cl: CROMULENT DCLP ‘View in PN’ hack
  # name can be »papyri.info/dclp/SoSOL;2017;0002«
  def get_catalog_link
    "/#{DCLPMetaIdentifier::IDENTIFIER_NAMESPACE}/#{name[%r{.+/(\d+[a-z]*|SoSOL;\d{4};\d{4})$}, 1]}"
  end

  def correspondingDclpTextIdentifier
    publication.controlled_identifiers.each do |i|
      return i if i.instance_of?(DCLPTextIdentifier)
    end
  end
end
