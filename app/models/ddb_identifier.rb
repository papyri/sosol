# - Sub-class of Identifier
# - Includes acts_as_leiden_plus defined in vendor/plugins/rxsugar/lib/jruby_helper.rb
class DDBIdentifier < Identifier
  PATH_PREFIX = 'DDB_EpiDoc_XML'.freeze

  FRIENDLY_NAME = 'DDbDP Text'.freeze

  IDENTIFIER_NAMESPACE = 'ddbdp'.freeze
  TEMPORARY_COLLECTION = 'sosol'.freeze

  XML_VALIDATOR = JRubyXML::EpiDocP5Validator

  BROKE_LEIDEN_MESSAGE = "Broken Leiden+ below saved to come back to later:\n".freeze

  # defined in vendor/plugins/rxsugar/lib/jruby_helper.rb
  acts_as_leiden_plus

  # Returns value for 'id' attribute in DDB Text template
  def id_attribute
    ddb_collection_name, ddb_volume_number, ddb_document_number =
      to_components.last.split(';')

    ddb_collection_name.downcase!

    [ddb_collection_name, ddb_volume_number, ddb_document_number].compact_blank.join('.')
  end

  # Returns value for 'n' attribute in DDB Text template
  def n_attribute
    to_components[2..-1].join(';')
  end

  # Returns value from id_attribute as value for 'title' attribute in DDB Text template
  def xml_title_text
    id_attribute
  end

  def self.collection_names
    collection_names_hash.keys
  end

  def self.collection_names_hash
    CollectionIdentifier.collection_names_hash
  end

  # Returns file path to DDB Text XML - e.g. DDB_EpiDoc_XML/bgu/bgu.10/bgu.10.1901.xml
  def to_path
    path_components = [PATH_PREFIX]

    ddb_collection_name, ddb_volume_number, ddb_document_number =
      to_components[2..-1].join('/').split(';')

    # switch commas to dashes
    # e.g. 0001:13:2230,1 => bgu/bgu.13/bgu.13.2230-1.xml
    ddb_document_number.tr!(',', '-')

    # switch forward slashes to underscores
    # e.g. 0014:2:1964/1967 => o.bodl/o.bodl.2/o.bodl.2.1964_1967.xml
    ddb_document_number.tr!('/', '_')

    raise 'DDB Collection Name Not Found' if ddb_collection_name.nil?

    # e.g. bgu.10
    ddb_volume_path = "#{ddb_collection_name}.#{ddb_volume_number}"
    # e.g. bgu.10.1901.xml
    ddb_xml_path_components = []
    ddb_xml_path_components << ddb_collection_name
    ddb_xml_path_components << ddb_volume_number unless ddb_volume_number.empty?
    ddb_xml_path_components << ddb_document_number << 'xml'
    ddb_xml_path = ddb_xml_path_components.join('.')

    path_components << ddb_collection_name
    path_components << ddb_volume_path unless ddb_volume_number.empty?
    path_components << ddb_xml_path

    # e.g. DDB_EpiDoc_XML/bgu/bgu.10/bgu.10.1901.xml
    File.join(path_components)
  end

  # Place any actions you always want to perform on DDB Text identifier content prior to it being committed in this method
  # - *Args*  :
  #   - +content+ -> DDBIdentifier XML as string
  def before_commit(content)
    DDBIdentifier.preprocess(content)
  end

  # Applies the preprocess XSLT to 'content'
  # - *Args*  :
  #   - +content+ -> XML as string
  # - *Returns* :
  #   - modified 'content'
  def self.preprocess(content)
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(content),
      JRubyXML.stream_from_file(File.join(Rails.root,
                                          %w[data xslt ddb preprocess.xsl]))
    )
  end

  def after_rename(options = {})
    dummy_header(options)
    update_header(options)
  end

  def dummy_header(options = {})
    original = options[:original]

    # copy back the content to the original name before we update the header
    if options[:set_dummy_header] && (options[:set_dummy_header] != 'false')
      dummy_comment_text = "Add dummy header for original identifier '#{original.name}' pointing to new identifier '#{name}'"
      dummy_header =
        JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(content),
          JRubyXML.stream_from_file(File.join(Rails.root,
                                              %w[data xslt ddb dummyize.xsl])),
          reprint_in_text: title,
          ddb_hybrid_ref_attribute: n_attribute
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
  end

  def update_header(options = {})
    original = options[:original]

    if options[:update_header]
      rewritten_xml =
        JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(content),
          JRubyXML.stream_from_file(File.join(Rails.root,
                                              %w[data xslt ddb update_header.xsl])),
          title_text: xml_title_text,
          human_title_text: titleize,
          filename_text: id_attribute,
          ddb_hybrid_text: n_attribute,
          reprint_from_text: options[:set_dummy_header] ? original.title : '',
          ddb_hybrid_ref_attribute: options[:set_dummy_header] ? original.n_attribute : ''
        )

      set_xml_content(rewritten_xml, comment: "Update header to reflect new identifier '#{name}'")
    end
  end

  # - Updates DDBIdentifier XML with line by line commentary
  # - Uses update_commentary.xsl
  # - Saves the XML containing line by line commentary to the repository
  #
  # - *Args*  :
  #   - +line_id+ -> generated id of this lines 'lb' tag within the XML file to consistently reference this line
  #     irregardless of the +reference+ value described below. This will become invalid if new 'lb' lines added
  #     to the file
  #   - +reference+ -> the value of the 'n' attribute on the 'lb' tag for the line adding the commentary for
  #   - +comment_content+ -> the line by line commentary being added in XML format
  #   - +original_item_id+ -> generated id of the 'item' tag containing the commentary for this line - set
  #     in commentary.xsl
  #   - +delete_comment+ -> if set to true, will delete the commentary associated with this line_id
  def update_commentary(line_id, reference, comment_content = '', original_item_id = '', delete_comment = false)
    rewritten_xml =
      JRubyXML.apply_xsl_transform(
        JRubyXML.stream_from_string(
          DDBIdentifier.preprocess(xml_content)
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

  # - Updates DDBIdentifier XML with front matter commentary
  # - Makes use of update_frontmatter_commentary.xsl
  # - Saves the XML containing front matter commentary to the repository
  #
  #
  # - *Args*  :
  #   - +commentary_content+ -> the front matter commentary being added in XML format
  #   - +delete_commentary+ -> if set to true, will delete the front matter commentary for this publication
  def update_frontmatter_commentary(commentary_content, delete_commentary = false)
    rewritten_xml =
      JRubyXML.apply_xsl_transform(
        JRubyXML.stream_from_string(
          DDBIdentifier.preprocess(xml_content)
        ),
        JRubyXML.stream_from_file(File.join(Rails.root,
                                            %w[data xslt ddb update_frontmatter_commentary.xsl])),
        content: commentary_content,
        delete_commentary: (delete_commentary ? 'true' : '')
      )

    set_xml_content(rewritten_xml, comment: '')
  end

  # Extracts 'Leiden+ that will not parse' from DDB Text XML file if it was saved by the user
  #
  # - *Args*  :
  #   - +original_xml+ -> REXML::Document/XML to look for broken Leiden+ in. If nil, will retrieve from the
  #     repository based on the the DDB Text Identifier currently processing
  # - *Returns* :
  #   - +nil+ - if broken Leiden+ is not in the XML file
  #   - +brokeleiden+ - the broken Leiden+ extracted from the XML
  def get_broken_leiden(original_xml = nil)
    original_xml_content = original_xml || REXML::Document.new(xml_content)
    brokeleiden_path = '/TEI/text/body/div[@type = "edition"]/div[@subtype = "brokeleiden"]/note'
    brokeleiden_here = REXML::XPath.first(original_xml_content, brokeleiden_path)
    if brokeleiden_here.nil?
      nil
    else
      brokeleiden = brokeleiden_here.get_text.value

      brokeleiden.sub(/^#{Regexp.escape(BROKE_LEIDEN_MESSAGE)}/o, '')
    end
  end

  # - Retrieves the XML for the the DDB Text identifier currently processing from the repository
  # - Applies preprocessing and cleanup via XSLT
  # - Checks if XML contains 'broken Leiden+"
  #
  # - *Returns* :
  #   - +nil+ - if broken Leiden+ is in the XML file
  #   - +transformed+ - Leiden+ transformed from the XML via Xsugar
  def leiden_plus
    original_xml = DDBIdentifier.preprocess(xml_content)

    # strip xml:id from lb's
    original_xml = JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(original_xml),
      JRubyXML.stream_from_file(File.join(Rails.root,
                                          %w[data xslt ddb strip_lb_ids.xsl]))
    )

    original_xml_content = REXML::Document.new(original_xml)

    # if XML does not contain broke Leiden+ send XML to be converted to Leiden+ and return that
    # otherwise, return nil (client can then get_broken_leiden)
    if get_broken_leiden(original_xml_content).nil?
      # get div type=edition from XML in string format for conversion
      abs = DDBIdentifier.get_div_edition(original_xml).join
      # if there’s only an empty stub, add a single line to make it valid for xsugar grammar and add default language if there is none
      if %r{\A<div[^>]+/>\Z}.match?(abs)
        abs = "#{abs[0..-3]}#{/xml:lang/.match?(abs) ? '' : ' xml:lang="grc"'}><ab><lb n=\"1\"/></ab></div>"
      end
      # transform XML to Leiden+
      DDBIdentifier.xml2nonxml(abs)

    end
  end

  # - Preprocesses the Leiden+ for character consistency and Xsugar grammar
  # - Transforms Leiden+ to XML
  # - Saves the newly transformed XML to the repository
  #
  # - *Args*  :
  #   - +leiden_plus_content+ -> the Leiden+ to transform into XML
  #   - +comment+ -> the comment from the user to attach to this repository commit and put in the comment table
  # - *Returns* :
  #   -  a String of the SHA1 of the commit
  def set_leiden_plus(leiden_plus_content, comment)
    pp_leiden = preprocess_leiden(leiden_plus_content)

    # transform back to XML
    xml_content = leiden_plus_to_xml(
      pp_leiden
    )
    # commit xml to repo
    set_xml_content(xml_content, comment: comment)
  end

  def reprinted_in
    REXML::XPath.first(REXML::Document.new(xml_content),
                       "/TEI/text/body/head/ref[@type='reprint-in']/@n")
  end

  def is_reprinted?
    !reprinted_in.nil?
  end

  # Override REXML::Attribute#to_string so that attributes are defined
  # with double quotes instead of single quotes
  REXML::Attribute.class_eval(%q^
    def to_string
      %Q[#@expanded_name="#{to_s().gsub(/"/, '&quot;')}"]
    end
  ^, __FILE__, __LINE__ - 4)

  # - Transforms Leiden+ to XML
  # - Retrieves the current version of XML for this DDBIdentifier
  # - Replace the 'div type = "edition"' with the newly transformed XML
  #
  # - *Args*  :
  #   - +content+ -> the Leiden+ to transform into XML
  # - *Returns* :
  #   -  +modified_xml_content+ - XML with the 'div type = "edition"' containing the newly transformed XML
  def leiden_plus_to_xml(content)
    # transform the Leiden+ to XML
    nonx2x = DDBIdentifier.nonxml2xml(content)

    # remove namespace from XML returned from XSugar
    nonx2x.sub!(%r{ xmlns:xml="http://www.w3.org/XML/1998/namespace"}, '')

    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(xml_content),
      JRubyXML.stream_from_file(File.join(Rails.root,
                                          %w[data xslt ddb update_edition.xsl])),
      new_edition: nonx2x.force_encoding('UTF-8')
    )
  end

  # - Retrieves the current version of XML for this DDBIdentifier
  # - Delete/Add the 'div type = "edition" subtype = "brokeleiden"' that contains the broken Leiden+
  # - Saves the XML containing the 'broken Leiden_' to the repository
  #
  # - *Args*  :
  #   - +brokeleiden+ -> the Leiden+ that will not transform to save in the XML
  #   - +commit_comment+ -> the comment from the user to attach to this repository commit and put
  def save_broken_leiden_plus_to_xml(brokeleiden, commit_comment = '')
    modified_xml_content =
      JRubyXML.apply_xsl_transform(
        JRubyXML.stream_from_string(xml_content),
        JRubyXML.stream_from_file(File.join(Rails.root,
                                            %w[data xslt ddb update_brokeleiden.xsl])),
        new_brokeleiden: brokeleiden.force_encoding('UTF-8'),
        brokeleiden_message: BROKE_LEIDEN_MESSAGE
      )

    Rails.logger.info(modified_xml_content)

    # commit xml to repo
    set_xml_content(modified_xml_content, comment: commit_comment)
  end

  # - Retrieves the current version of XML for this DDBIdentifier
  # - Processes XML with preview.xsl XSLT
  #
  # - *Returns* :
  #   -  Preview HTML
  def preview(parameters = {}, xsl = nil)
    parameters.reverse_merge!(
      'leiden-style' => 'ddbdp',
      'apparatus-style' => 'ddbdp',
      'edn-structure' => 'ddbdp',
      'css-loc' => ''
    )
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(xml_content),
      JRubyXML.stream_from_file(File.join(Rails.root,
                                          xsl || %w[data xslt ddb preview.xsl])),
      parameters
    )
  end

  # - Mass substitute alternate keyboard characters for Leiden+ grammar characters
  # - Mass substitute for consistent characters across the canonical repository (ex. - LT symbol, square brackets, etc)
  #
  # - *Args*  :
  #   - +preprocessed_leiden+ -> the Leiden+ to perfrom substitutions on
  # - *Returns* :
  #   -  +preprocessed_leiden+ - the Leiden+ after substitutions done
  def preprocess_leiden(preprocessed_leiden)
    # mass substitute alternate keyboard characters for Leiden+ grammar characters

    # strip tabs
    preprocessed_leiden.tr!("\t", '')

    # convert multiple underdots (\u0323) to a single underdot
    underdot = [0x323].pack('U')
    preprocessed_leiden.gsub!(/#{underdot}+/, underdot)

    # consistent LT symbol (<)
    # \u2039 \u2329 \u27e8 \u3008 to \u003c')
    preprocessed_leiden.gsub!(/[‹〈⟨〈]{1}/, '<')

    # consistent GT symbol (>)
    # \u203a \u232a \u27e9 \u3009 to \u003e')
    preprocessed_leiden.gsub!(/[›〉⟩〉]{1}/, '>')

    # consistent Left square bracket (〚)
    # \u27e6 to \u301a')
    preprocessed_leiden.gsub!(/⟦/, '〚')

    # consistent Right square bracket (〛)
    # \u27e7 to \u301b')
    preprocessed_leiden.gsub!(/⟧/, '〛')

    # consistent macron (¯)
    # \u02c9 to \u00af')
    preprocessed_leiden.gsub!(/ˉ/, '¯')

    # consistent hyphen in linenumbers (-)
    # immediately preceded by a period
    # \u2010 \u2011 \u2012 \u2013 \u2212 \u10191 to \u002d')
    preprocessed_leiden.gsub!(/\.{1}[‐‑‒–−𐆑]{1}/, '.-')

    # consistent hyphen in gap ranges (-)
    # between 2 numbers
    # \u2010 \u2011 \u2012 \u2013 \u2212 \u10191 to \u002d')
    preprocessed_leiden.gsub!(/(\d+)([‐‑‒–−𐆑]{1})(\d+)/, '\1-\3')

    # convert greek perispomeni \u1fc0 into combining greek perispomeni \u0342
    combining_perispomeni = [0x342].pack('U')
    preprocessed_leiden.gsub!(/#{[0x1fc0].pack('U')}/, combining_perispomeni)

    # normalize to normalized form C
    preprocessed_leiden.unicode_normalize!(:nfc)

    preprocessed_leiden
  end
end
