class TEICTSIdentifier < CTSIdentifier
  PATH_PREFIX = 'CTS_XML_TEI'.freeze

  FRIENDLY_NAME = 'Manuscript Transcription'.freeze

  IDENTIFIER_NAMESPACE = 'teia_edition'.freeze

  XML_VALIDATOR = JRubyXML::TEIAValidator

  XML_CITATION_PREPROCESSOR = 'preprocess_teia_passage.xsl'.freeze

  def before_commit(content)
    TEICTSIdentifier.preprocess(content)
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
          TEICTSIdentifier.preprocess(xml_content)
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
          TEICTSIdentifier.preprocess(xml_content)
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
    Epidocinator.apply_xsl_transform(
      Epidocinator.stream_from_string(xml_content),
      {
        'xsl' => 'makehtmlfragment',
        'collection' => IDENTIFIER_NAMESPACE
      }
    )
  end
end
