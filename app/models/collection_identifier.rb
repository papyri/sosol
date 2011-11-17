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

  def add_collection(short_name, long_name, actor)
    unless self.has_collection?(short_name)
      self.set_xml_content(collection_xml_with_new_collection(short_name, long_name),
                           :comment => "Add collection #{short_name} = #{long_name}",
                           :actor => actor.grit_actor)
      self.class.add_collection_to_collection_names_hash(short_name, long_name)
    end
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

  def has_collection?(short_name)
    rdf = REXML::Document.new(self.xml_content)

    xpath = "/rdf:RDF/rdf:Description[@rdf:about = '#{self.class.short_name_to_identifier(short_name)}']"
    if REXML::XPath.first(rdf, xpath).nil?
      return false
    else
      return true
    end
  end

  def self.collection_names_hash
    unless defined? @collection_names_hash
      @collection_names_hash = Hash.new()
      rdf = REXML::Document.new(self.new.xml_content)
      rdf.root.elements.each('rdf:Description') do |description_node|
        about = description_node.attributes['rdf:about']
        unless about.nil?
          citation = REXML::XPath.first(description_node, 'dcterms:bibliographicCitation')
          unless citation.nil?
            @collection_names_hash[about.split('/').last] = citation.text
          end
        end
      end
    end
    return @collection_names_hash
  end

  def self.add_collection_to_collection_names_hash(short_name, long_name)
    self.collection_names_hash
    @collection_names_hash[short_name] = long_name
  end
end
