class HGVIdentifier < Identifier
  # This is a superclass for HGVMetaIdentifier and HGVTransIdentifier
  # shared constants and methods. No instances of HGVIdentifier should be
  # created. Should probably be modularized and mixed in.
  
  IDENTIFIER_NAMESPACE = 'hgv'
  TEMPORARY_COLLECTION = 'SoSOL'
  
  FRIENDLY_NAME = "HGV Identifier"
  
  def temporary_path
    # path constructor for born-digital temporary SoSOL identifiers
    trimmed_name = name.sub(/papyri.info\/hgv\//, '')
    components = trimmed_name.split(';')
    return File.join(self.class::PATH_PREFIX, components[0..-2], "#{components[-1]}.xml")
  end
  
  def self.collection_names_hash
    self.collection_names
    
    unless defined? @collection_names_hash
      @collection_names_hash = {TEMPORARY_COLLECTION => TEMPORARY_COLLECTION}
      @collection_names.each do |collection_name|
        human_name = collection_name.tr('_',' ')
        @collection_names_hash[collection_name] = human_name
      end
    end
    
    return @collection_names_hash
  end
end