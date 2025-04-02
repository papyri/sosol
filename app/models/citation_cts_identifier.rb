class CitationCTSIdentifier < CTSIdentifier
  PATH_PREFIX = 'CTS_XML_CITATIONS'.freeze
  IDENTIFIER_NAMESPACE = 'citation'.freeze
  FRIENDLY_NAME = 'Passage Text'.freeze

  def related_text
    parent_urn = CTS::CTSLib.urnObj(urn_attribute).getUrnWithoutPassage
    publication.identifiers.select do |i|
      i.respond_to? :urn_attribute
    end.reverse.find { |i| i.urn_attribute == parent_urn }
  end

  def is_valid_xml?(content = nil)
    content = xml_content if content.nil?
    # Before checking for validity, preprocess according to requirements of the parent text
    xslt = related_text.class::XML_CITATION_PREPROCESSOR
    Rails.logger.info("Preprocessing citation xml with #{xslt}")
    fixed = JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(content),
      JRubyXML.stream_from_file(File.join(Rails.root,
                                          %w[data xslt cts], xslt))
    )
    # Validate Citation XML with a validator specific to the parent class
    related_text.class::XML_VALIDATOR.instance.validate(
      JRubyXML.input_source_from_string(fixed)
    )
  end

  def self.new_from_template(publication, a_inventory, passage_urn, pubtype)
    document_path = "#{a_inventory}/#{CTS::CTSLib.pathForUrn(passage_urn, pubtype)}"
    new_identifier = new(name: document_path)
    new_identifier.publication = publication

    # create the identifier title by prefixing the passage component parts with their citation labels
    # from the parent cts inventory
    urnObj = CTS::CTSLib.urnObj("urn:cts:#{passage_urn}")
    citeLevel = urnObj.getCitationDepth
    citeinfo = new_identifier.related_text.related_inventory.parse_inventory
    passageParts = urnObj.getPassage(citeLevel).split('.')
    titleParts = []
    (0..citeLevel - 1).each do |i|
      titleParts << "#{citeinfo['citations'][i]} #{passageParts[i]}"
    end
    new_identifier.title = titleParts.join(' ')
    new_identifier.save!
    begin
      uuid = publication.id.to_s + passage_urn.tr(':', '_')
      inventory = new_identifier.related_text.related_inventory.xml_content
      document = new_identifier.related_text.content
      passage_xml = CTS::CTSLib.getPassageFromRepo(inventory, document, new_identifier.urn_attribute, uuid)
      new_identifier.set_xml_content(passage_xml, comment: 'extracted passage')
      new_identifier
    rescue StandardError => e
      new_identifier.destroy
      raise e
    end
  end

  # Override REXML::Attribute#to_string so that attributes are defined
  # with double quotes instead of single quotes
  REXML::Attribute.class_eval(%q^
    def to_string
      %Q[#@expanded_name="#{to_s().gsub(/"/, '&quot;')}"]
    end
  ^, __FILE__, __LINE__ - 4)

  def preview(parameters = {}, xsl = nil)
    # Seems to be missing aparatus?
    Epidocinator.apply_xsl_transform(
      Epidocinator.stream_from_string(xml_content),
      {
        'xsl' => 'makehtmlfragment',
        'collection' => IDENTIFIER_NAMESPACE
      }
    )
  end

  def preprocess_for_finalization
    # what we want to do:
    # merge passage back into parent text
    # send the parent text for review
    # passage itself doesn't get finalized
    # archive? the passage

    # only do this once
    if status == 'finalizing-preprocessed'
      false
    else
      document = related_text.content
      begin
        updated = CTS::CTSLib.proxyUpdatePassage(content, related_text.related_inventory.xml_content,
                                                 related_text.content, urn_attribute, get_recent_commit_sha)
      rescue StandardError => e
        # TODO: if we are unable to merge the citation back into the source document,
        # we should support submitting it on its own?
        Rails.logger.error(e)
        raise e
      else
        related_text.set_xml_content(updated, comment: "merged updated passage #{urn_attribute}")
        self.status = 'finalizing-preprocessed' # TODO: check this
      end
      true
    end
  end
end
