class EpiTransCTSIdentifier < EpiCTSIdentifier   
  
  PATH_PREFIX = 'CTS_XML_EpiDoc'
  TEMPORARY_COLLECTION = 'perseids'
  TEMPORARY_TITLE = 'New Translation'
  
  FRIENDLY_NAME = "Translation Text (EpiDoc)"
  
  IDENTIFIER_NAMESPACE = 'epigraphy_translation'
  
  XML_VALIDATOR = JRubyXML::EpiDocP5Validator
   
  # defined in vendor/plugins/rxsugar/lib/jruby_helper.rb
  acts_as_translation
  
  def self.new_from_template(publication,inventory,urn,pubtype,lang)
    new_identifier = self.new(:name => self.next_temporary_identifier(inventory,urn,pubtype,lang))
    new_identifier.publication = publication
    new_identifier.save!    
    new_identifier.stub_text_structure(lang,new_identifier.id_attribute)     
    return new_identifier
  end
    
  def before_commit(content)
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(content),
      JRubyXML.stream_from_file(File.join(Rails.root,
        %w{data xslt translation preprocess.xsl}))
    )
  end

  def lang
    parsed = XmlHelper::parseattributes(self.xml_content,
      {"http://www.tei-c.org/ns/1.0 div" => 
        ['type','http://www.w3.org/XML/1998/namespace lang'] })
    langs = parsed['http://www.tei-c.org/ns/1.0 div'].select{ |e| 
      e['type'] == 'translation'
    }
    if (langs.size > 0) 
      langs.first['http://www.w3.org/XML/1998/namespace lang']
    else
      ''
    end
  end
  
  def translation_already_in_language?(lang)
    lang_path = '/TEI/text/body/div[@type = "translation" and @xml:lang = "' + lang + '"]'
    
    doc = REXML::Document.new(self.xml_content)
    result = REXML::XPath.match(doc, lang_path)
    
    if result.length > 0
     return true
    else
      return false
    end
     
  end
  
  def related_text
    self.publication.identifiers.select{|i| (i.class == EpiCTSIdentifier) && !i.is_reprinted?}.last
  end
  
  def stub_text_structure(lang,urn)
    Rails.logger.info("transforming template for #{urn}")
    if (self.related_text.nil?)
      template = self.file_template
    else 
      template = self.related_text.xml_content
    end
    translation_stub_xml =
      JRubyXML.apply_xsl_transform(
        JRubyXML.stream_from_string(template),
        JRubyXML.stream_from_file(File.join(RAILS_ROOT,
          %w{data xslt perseus epi_to_translation_xsl.xsl})),
        :lang => lang,
        :urn => urn  
      )
    
    self.set_xml_content(translation_stub_xml, :comment => "New translation stub for @xml:lang='#{lang}'")
  end
    
  def after_rename(options = {})
    if options[:update_header]
      rewritten_xml =
        JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(content),
          JRubyXML.stream_from_file(File.join(Rails.root,
            %w{data xslt translation update_header.xsl})),
          :filename_text => self.to_components.last,
          :title_text => NumbersRDF::NumbersHelper::identifier_to_title([NumbersRDF::NAMESPACE_IDENTIFIER,CTSIdentifier::IDENTIFIER_NAMESPACE,self.to_components.last].join('/'))
        )
    
      self.set_xml_content(rewritten_xml, :comment => "Update header to reflect new identifier '#{self.name}'")
    end
  end
  
  def preview
      JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(self.xml_content),
      JRubyXML.stream_from_file(File.join(Rails.root,
        %w{data xslt perseus epidoc_preview.xsl})))
  end

  def text_content
    doc = REXML::Document.new(self.xml_content)
    ab = REXML::XPath.first(doc,'/TEI/text/body/div[@type = "translation"]/ab')
    ab.nil? ? '' : ab.text
  end

  def update_text_content(text,comment)
    doc = REXML::Document.new(self.xml_content)
    ab = REXML::XPath.first(doc,'/TEI/text/body/div[@type = "translation"]/ab')
    Rails.logger.info("Updating ab #{ab}")
    unless ab.nil?
      Rails.logger.info("Setting text to #{text}")
      ab.text = text
      formatter = PrettySsime.new
      formatter.compact = true
      formatter.width = 2**32
      modified_xml_content = ''
      formatter.write doc, modified_xml_content
      modified_xml_content
      self.set_xml_content(modified_xml_content, :comment => comment)
    end
  end
  
end
