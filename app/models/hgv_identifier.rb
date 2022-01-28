# - Sub-class of Identifier
# - This is a superclass for HGVMetaIdentifier and HGVTransIdentifier
#   shared constants and methods. No instances of HGVIdentifier should be
#   created.
class HGVIdentifier < Identifier
  # Should probably be modularized and mixed in.

  IDENTIFIER_NAMESPACE = 'hgv'.freeze
  TEMPORARY_COLLECTION = 'SoSOL'.freeze
  XML_VALIDATOR = JRubyXML::HGVEpiDocValidator

  FRIENDLY_NAME = 'HGV Identifier'.freeze

  # Path constructor for born-digital temporary SoSOL identifiers
  def temporary_path
    trimmed_name = name.sub(%r{papyri.info/(hgv|dclp|)/}, '')
    components = trimmed_name.split(';')
    File.join(self.class::PATH_PREFIX, components[0..-2], "#{components[-1]}.xml")
  end

  # Used as a workaround for e.g. @identifier[:arbitrarySymbol] non-database attributes,
  # which were removed in Rails 4
  def non_database_attribute
    @non_database_attribute ||= {}
  end

  # Creates a hash of the names of all the HGV Collections available in SoSOL replacing '_' with space
  # - used in selector
  def self.collection_names_hash
    collection_names

    unless defined? @collection_names_hash
      @collection_names_hash = { TEMPORARY_COLLECTION => TEMPORARY_COLLECTION }
      @collection_names.each do |collection_name|
        human_name = collection_name.tr('_', ' ')
        @collection_names_hash[collection_name] = human_name
      end
    end

    @collection_names_hash
  end
end
