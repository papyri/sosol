# - Sub-class of Identifier
class CollectionIdentifier < Identifier
  PATH_PREFIX = 'RDF'

  XML_VALIDATOR = JRubyXML::RDFValidator

  def to_path
    File.join(PATH_PREFIX, 'collection.rdf')
  end

  def self.short_name_to_identifier(short_name)
    return NumbersRDF::NumbersHelper.identifier_to_url([NumbersRDF::NAMESPACE_IDENTIFIER, DDBIdentifier::IDENTIFIER_NAMESPACE, short_name].join('/'))
  end

  def add_collection(short_name, long_name)
    self.set_xml_content(collection_xml_with_new_collection(short_name, long_name),
                         :comment => "Add collection #{short_name} = #{long_name}",
                         :actor => User.first.grit_actor)
  end

  def collection_xml_with_new_collection(short_name, long_name)
    rdf = REXML::Document.new(self.xml_content)
    description = rdf.root.add_element 'rdf:Description', {'rdf:about'=>self.class.short_name_to_identifier(short_name)}
    bibiographicCitation = description.add_element 'dcterms:bibliographicCitation'
    bibiographicCitation.add_text long_name

    modified_xml_content = ''
    formatter = REXML::Formatters::Pretty.new(4)
    formatter.compact = true
    formatter.width = 512
    formatter.write rdf, modified_xml_content

    return modified_xml_content
  end
end
