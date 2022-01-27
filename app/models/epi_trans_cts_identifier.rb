# frozen_string_literal: true

class EpiTransCTSIdentifier < EpiCTSIdentifier
  PATH_PREFIX = 'CTS_XML_EpiDoc'
  TEMPORARY_COLLECTION = 'TempTrans'
  TEMPORARY_TITLE = 'New Translation'

  FRIENDLY_NAME = 'Inscription Translation'

  IDENTIFIER_NAMESPACE = 'epigraphy_translation'

  XML_VALIDATOR = JRubyXML::EpiDocP5Validator

  # defined in vendor/plugins/rxsugar/lib/jruby_helper.rb
  acts_as_translation

  def self.new_from_template(publication, inventory, urn, pubtype, lang)
    new_identifier = new(name: next_temporary_identifier(inventory, urn, pubtype, lang))
    new_identifier.publication = publication
    new_identifier.save!
    new_identifier.stub_text_structure(lang, new_identifier.id_attribute)
    new_identifier
  end

  def before_commit(content)
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(content),
      JRubyXML.stream_from_file(File.join(Rails.root,
                                          %w[data xslt translation preprocess.xsl]))
    )
  end

  def translation_already_in_language?(lang)
    lang_path = "/TEI/text/body/div[@type = \"translation\" and @xml:lang = \"#{lang}\"]"

    doc = REXML::Document.new(xml_content)
    result = REXML::XPath.match(doc, lang_path)

    if result.length.positive?
      true
    else
      false
    end
  end

  def related_text
    publication.identifiers.select { |i| i.instance_of?(EpiCTSIdentifier) && !i.is_reprinted? }.last
  end

  def stub_text_structure(lang, urn)
    Rails.logger.info("transforming template for #{urn}")
    translation_stub_xml =
      JRubyXML.apply_xsl_transform(
        JRubyXML.stream_from_string(related_text.xml_content),
        JRubyXML.stream_from_file(File.join(Rails.root,
                                            %w[data xslt translation epi_to_translation_xsl.xsl])),
        lang: lang,
        urn: urn
      )

    set_xml_content(translation_stub_xml, comment: "New translation stub for @xml:lang='#{lang}'")
  end

  def after_rename(options = {})
    if options[:update_header]
      rewritten_xml =
        JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(content),
          JRubyXML.stream_from_file(File.join(Rails.root,
                                              %w[data xslt translation update_header.xsl])),
          filename_text: to_components.last,
          title_text: NumbersRDF::NumbersHelper.identifier_to_title([NumbersRDF::NAMESPACE_IDENTIFIER,
                                                                     CTSIdentifier::IDENTIFIER_NAMESPACE, to_components.last].join('/'))
        )

      set_xml_content(rewritten_xml, comment: "Update header to reflect new identifier '#{name}'")
    end
  end

  def preview
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(xml_content),
      JRubyXML.stream_from_file(File.join(Rails.root,
                                          %w[data xslt pn start-divtrans-portlet.xsl]))
    )
  end
end
