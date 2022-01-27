# frozen_string_literal: true

class TeiCTSIdentifier < CTSIdentifier
  PATH_PREFIX = 'CTS_XML_TEI'

  FRIENDLY_NAME = 'Manuscript Transcription'

  IDENTIFIER_NAMESPACE = 'teia_edition'

  XML_VALIDATOR = JRubyXML::TEIAValidator

  XML_CITATION_PREPROCESSOR = 'preprocess_teia_passage.xsl'

  def before_commit(content)
    TeiCTSIdentifier.preprocess(content)
  end

  def self.preprocess(content)
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(content),
      JRubyXML.stream_from_file(File.join(Rails.root,
                                          %w[data xslt cts validate_teia.xsl]))
    )
  end

  def update_commentary(line_id, reference, comment_content = '', original_item_id = '', delete_comment = false)
    rewritten_xml =
      JRubyXML.apply_xsl_transform(
        JRubyXML.stream_from_string(
          TeiCTSIdentifier.preprocess(xml_content)
        ),
        JRubyXML.stream_from_file(File.join(Rails.root,
                                            %w[data xslt ddb update_commentary.xsl])),
        line_id: line_id,
        reference: reference,
        content: comment_content,
        original_item_id: original_item_id,
        delete_comment: (delete_comment ? 'true' : '')
      )

    set_xml_content(rewritten_xml, comment: '')
  end

  def update_frontmatter_commentary(commentary_content, delete_commentary = false)
    rewritten_xml =
      JRubyXML.apply_xsl_transform(
        JRubyXML.stream_from_string(
          TeiCTSIdentifier.preprocess(xml_content)
        ),
        JRubyXML.stream_from_file(File.join(Rails.root,
                                            %w[data xslt ddb update_frontmatter_commentary.xsl])),
        content: commentary_content,
        delete_commentary: (delete_commentary ? 'true' : '')
      )

    set_xml_content(rewritten_xml, comment: '')
  end

  # Override REXML::Attribute#to_string so that attributes are defined
  # with double quotes instead of single quotes
  REXML::Attribute.class_eval(%q^
    def to_string
      %Q[#@expanded_name="#{to_s().gsub(/"/, '&quot;')}"]
    end
  ^, __FILE__, __LINE__ - 4)

  def preview(parameters = {}, xsl = nil)
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(xml_content),
      JRubyXML.stream_from_file(File.join(Rails.root,
                                          xsl || %w[data xslt cts alpheios-tei.xsl])),
      parameters
    )
  end
end
