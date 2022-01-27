# frozen_string_literal: true

class EpiCTSIdentifier < CTSIdentifier
  require 'json'

  PATH_PREFIX = 'CTS_XML_EpiDoc'

  FRIENDLY_NAME = 'Inscription Text'

  IDENTIFIER_NAMESPACE = 'epigraphy_edition'

  XML_VALIDATOR = JRubyXML::EpiDocP5Validator

  def before_commit(content)
    EpiCTSIdentifier.preprocess(content)
  end

  def self.preprocess(content)
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(content),
      JRubyXML.stream_from_file(File.join(Rails.root,
                                          %w[data xslt ddb preprocess.xsl]))
    )
  end

  def after_rename(options = {})
    # copy back the content to the original name before we update the header
    if options[:set_dummy_header]
      original = options[:original]
      dummy_comment_text = "Add dummy header for original identifier '#{original.name}' pointing to new identifier '#{name}'"
      dummy_header =
        JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(content),
          JRubyXML.stream_from_file(File.join(Rails.root,
                                              %w[data xslt ddb dummyize.xsl]))
        )

      original.save!
      publication.identifiers << original

      dummy_header = add_change_desc(dummy_comment_text, publication.owner, dummy_header)
      original.set_xml_content(dummy_header, comment: dummy_comment_text)

      # need to do on originals too
      relatives.each do |relative|
        original_relative = relative.dup
        original_relative.name = original.name
        original_relative.title = original.title
        relative.save!

        relative.publication.identifiers << original_relative

        # set the dummy header on the relative
        original_relative.set_xml_content(dummy_header, comment: dummy_comment_text)
      end
    end

    if options[:update_header]
      rewritten_xml =
        JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(content),
          JRubyXML.stream_from_file(File.join(Rails.root,
                                              %w[data xslt ddb update_header.xsl])),
          title_text: xml_title_text,
          human_title_text: titleize,
          filename_text: urn_attribute
        )

      set_xml_content(rewritten_xml, comment: "Update header to reflect new identifier '#{name}'")
    end
  end

  def update_commentary(line_id, reference, comment_content = '', original_item_id = '', delete_comment = false)
    rewritten_xml =
      JRubyXML.apply_xsl_transform(
        JRubyXML.stream_from_string(
          EpiCTSIdentifier.preprocess(xml_content)
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
          EpiCTSIdentifier.preprocess(xml_content)
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
                                          xsl || %w[data xslt pn start-div-portlet_perseus.xsl])),
      parameters
    )
  end

  def facs(parameters = {}, xsl = nil)
    links = JSON.parse(
      JRubyXML.apply_xsl_transform(
        JRubyXML.stream_from_string(xml_content),
        JRubyXML.stream_from_file(File.join(Rails.root,
                                            xsl || %w[data xslt cts facs.xsl])),
        parameters
      )
    )
  end
end
