class TEITransCTSIdentifier < TEICTSIdentifier
  PATH_PREFIX = 'CTS_XML_TEI'.freeze
  TEMPORARY_COLLECTION = 'TempTrans'.freeze
  TEMPORARY_TITLE = 'New Translation'.freeze
  FRIENDLY_NAME = 'Manuscript Translation'.freeze
  IDENTIFIER_NAMESPACE = 'teia_translation'.freeze
  XML_VALIDATOR = JRubyXML::TEIAValidator

  # defined in vendor/plugins/rxsugar/lib/jruby_helper.rb
  acts_as_translation

  def self.new_from_template(publication, inventory, urn, pubtype, lang)
    new_identifier = new(name: next_temporary_identifier(inventory, urn, pubtype, lang))
    new_identifier.publication = publication
    new_identifier.save!
    new_identifier.stub_text_structure(lang, new_identifier.id_attribute)
    new_identifier
  end

  def translation_already_in_language?(lang)
    lang_path = "/TEI/text/body/div[@type = \"translation\" and @xml:lang = \"#{lang}\"]"

    doc = REXML::Document.new(xml_content)
    result = REXML::XPath.match(doc, lang_path)

    result.length.positive?
  end

  def related_text
    publication.identifiers.reverse.find { |i| i.instance_of?(TEICTSIdentifier) && !i.is_reprinted? }
  end

  def stub_text_structure(lang, urn)
    Rails.logger.info("transforming template for #{urn}")
    translation_stub_xml =
      JRubyXML.apply_xsl_transform(
        JRubyXML.stream_from_string(related_text.xml_content),
        JRubyXML.stream_from_file(File.join(Rails.root,
                                            %w[data xslt translation tei_to_translation_xsl.xsl])),
        lang: lang,
        urn: urn
      )

    set_xml_content(translation_stub_xml, comment: "New translation stub for @xml:lang='#{lang}'")
  end

  def after_rename(options = {})
    if options[:update_header]
      rewritten_xml =
        Epidocinator.apply_xsl_transform(
          Epidocinator.stream_from_string(content),
          {
            'xsl' => 'updatetranslation',
            'collection' => IDENTIFIER_NAMESPACE,
            'filename_text' => to_components.last,
            'title_text' => NumbersRDF::NumbersHelper.identifier_to_title([NumbersRDF::NAMESPACE_IDENTIFIER,
                                                                      CTSIdentifier::IDENTIFIER_NAMESPACE, to_components.last].join('/')),
            'reprint_from_text' => options[:set_dummy_header] ? options[:original].title : '',
            'reprint_ref_attribute' => options[:set_dummy_header] ? options[:original].to_components.last : ''
          }
        )

      set_xml_content(rewritten_xml, comment: "Update header to reflect new identifier '#{name}'")
    end
  end
end
