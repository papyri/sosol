class DCLPMetaIdentifier < HGVMetaIdentifier

  PATH_PREFIX = 'DCLP'

  FRIENDLY_NAME = "DCLP Meta"
  IDENTIFIER_NAMESPACE = 'dclp'

  XML_VALIDATOR = JRubyXML::DCLPEpiDocValidator

  # cl: needs to load additional xpaths
  # Loads +HgvMetaConfiguration+ object (HGV xpath for EpiDoc and options for the editor) and presets valid EpiDoc attributes
  # Side effect on +@configuration+ and + @valid_epidoc_attributes+
  def post_initialization_configuration
    @configuration = HgvMetaIdentifierHelper::HgvMetaConfiguration.new :dclp
    @valid_epidoc_attributes = @configuration.keys
  end

  # cl: can be made simpler for DCLP needs
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

  # cl: load DCLP text here?
  def n_attribute
    return nil
  end

  # cl: does dclp have other needs in terms of preprocessing the data
  # Place any actions you always want to perform on HGV Meta identifier content prior to it being committed in this method
  # - *Args*  :
  #   - +content+ -> HGVMetaIdentifier XML as string
  def before_commit(content)
    DCLPMetaIdentifier.preprocess(content)
  end

  def to_s
   serialization_string = ''
   @configuration.scheme.each_key do |key|
     serialization_string += '__' + key.to_s + '__: ' + self[key].to_s
   end
   return serialization_string
  end

  # cl: CROMULENT DCLP ‘View in PN’ hack
  def get_catalog_link
    '/' + DCLPMetaIdentifier::IDENTIFIER_NAMESPACE + '/' + self.name[/.+\/(\d+)$/, 1]
  end

end