# frozen_string_literal: true

# Used for directly manipulating +collection.rdf+ in the canonical repository.
# This is assumed to never have an instance belonging to a Publication.
# - Sub-class of Identifier
class CollectionIdentifier < Identifier
  # Repository path prefix
  PATH_PREFIX = 'RDF'

  # Validator to use for XML validation
  XML_VALIDATOR = JRubyXML::RDFValidator

  # *Returns*:
  # - path to +collection.rdf+ in repository as string
  def to_path
    File.join(PATH_PREFIX, 'collection.rdf')
  end

  # Given a short collection name, returns the identifier used for it inside +collection.rdf+.
  # e.g.: "bgu" -> "http://papyri.info/ddbdp/bgu"
  #
  # - *Args*:
  #   - +short_name+ collection short name as string
  # - *Returns*:
  #   - collection identifier as string
  def self.short_name_to_identifier(short_name)
    NumbersRDF::NumbersHelper.identifier_to_url([NumbersRDF::NAMESPACE_IDENTIFIER,
                                                 DDBIdentifier::IDENTIFIER_NAMESPACE, short_name].join('/'))
  end

  # Adds collection to +collection.rdf+ XML and commits it to the repository.
  # Also updates the memoized collection names hash.
  #
  # - *Args*:
  #   - +short_name+ collection short name as string, e.g. "p.nag.hamm"
  #   - +long_name+ collection long name as string, e.g. "P.Nag Hamm."
  #   - +actor+ instance of User class who will be responsible for the commit
  def add_collection(short_name, long_name, actor)
    unless has_collection?(short_name)
      set_xml_content(collection_xml_with_new_collection(short_name, long_name),
                      comment: "Add collection #{short_name} = #{long_name}",
                      actor: actor.jgit_actor)
      self.class.add_collection_to_collection_names_hash(short_name, long_name)
    end
  end

  # Adds collection to +collection.rdf+ XML, returning modified XML.
  # Does not actually commit anything, just used for XML manipulation.
  #
  # - *Args*:
  #   - +short_name+ collection short name as string, e.g. "p.nag.hamm"
  #   - +long_name+ collection long name as string, e.g. "P.Nag Hamm."
  # - *Returns*:
  #   - modified XML as string
  def collection_xml_with_new_collection(short_name, long_name)
    rdf = REXML::Document.new(xml_content)
    description = rdf.root.add_element 'rdf:Description',
                                       { 'rdf:about' => self.class.short_name_to_identifier(short_name) }
    bibiographicCitation = description.add_element 'dcterms:bibliographicCitation'
    bibiographicCitation.add_text long_name

    modified_xml_content = ''
    formatter = REXML::Formatters::Pretty.new(4)
    formatter.compact = true
    formatter.width = 512
    formatter.write rdf, modified_xml_content

    modified_xml_content
  end

  # Checks if +collection.rdf+ already contains the collection based on its short name.
  # Short names are transformed into identifiers for the check, and assumed to be unique.
  # This method does not use the memoized collection hash, and always hits the file directly.
  #
  # - *Args*:
  #   - +short_name+ collection short name as string
  # - *Returns*:
  #   - +true+ or +false+
  def has_collection?(short_name)
    rdf = REXML::Document.new(xml_content)

    xpath = "/rdf:RDF/rdf:Description[@rdf:about = '#{self.class.short_name_to_identifier(short_name)}']"
    if REXML::XPath.first(rdf, xpath).nil?
      false
    else
      true
    end
  end

  # Class method for accessing a memoized collection names hash built by parsing +collection.rdf+.
  #
  # - *Returns*:
  #   - Hash containing short_name -> long_name mappings
  def self.collection_names_hash
    unless defined? @collection_names_hash
      @collection_names_hash = {}
      rdf = REXML::Document.new(new.xml_content)
      rdf.root.elements.each('rdf:Description') do |description_node|
        about = description_node.attributes['rdf:about']
        next if about.nil?

        citation = REXML::XPath.first(description_node, 'dcterms:bibliographicCitation')
        @collection_names_hash[about.split('/').last] = citation.text unless citation.nil?
      end
    end
    @collection_names_hash
  end

  # Class method for adding a collection short name -> long name association to the memoized
  # collection names hash.
  #
  # - *Returns*:
  #   - Hash containing short_name -> long_name mappings
  def self.add_collection_to_collection_names_hash(short_name, long_name)
    collection_names_hash
    @collection_names_hash[short_name] = long_name
  end
end
