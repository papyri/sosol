class EpiCTSIdentifier < CTSIdentifier   
  require 'json'
  
  PATH_PREFIX = 'CTS_XML_EpiDoc'
  
  FRIENDLY_NAME = "Transcription Text (EpiDoc)"
  
  IDENTIFIER_NAMESPACE = 'epigraphy_edition'
  
  XML_VALIDATOR = JRubyXML::EpiDocP5Validator
  XML_CITATION_PREPROCESSOR = 'preprocess_epi_passage.xsl'

  # This is a somewhat arbitrary size restriction 
  # at some point would be nice to do something more intelligent  
  MAX_PREVIEW_SIZE = 50000

    
  def before_commit(content)
    EpiCTSIdentifier.preprocess(content)
  end
  
  def self.preprocess(content)
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(content),
      JRubyXML.stream_from_file(File.join(Rails.root,
        %w{data xslt ddb preprocess.xsl})))
  end
  
  def after_rename(options = {})
    # copy back the content to the original name before we update the header
    if options[:set_dummy_header]
      original = options[:original]
      dummy_comment_text = "Add dummy header for original identifier '#{original.name}' pointing to new identifier '#{self.name}'"
      dummy_header =
        JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(content),
          JRubyXML.stream_from_file(File.join(Rails.root,
            %w{data xslt ddb dummyize.xsl}))
        )
      
      original.save!
      self.publication.identifiers << original
      
      dummy_header = self.add_change_desc(dummy_comment_text, self.publication.owner, dummy_header)
      original.set_xml_content(dummy_header, :comment => dummy_comment_text)
            
      # need to do on originals too
      self.relatives.each do |relative|
        original_relative = relative.dup
        original_relative.name = original.name
        original_relative.title = original.title
        relative.save!
        
        relative.publication.identifiers << original_relative
        
        # set the dummy header on the relative
        original_relative.set_xml_content(dummy_header, :comment => dummy_comment_text)
      end
    end
    
    if options[:update_header]
      rewritten_xml =
        JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(content),
          JRubyXML.stream_from_file(File.join(Rails.root,
            %w{data xslt ddb update_header.xsl})),
          :title_text => self.xml_title_text,
          :human_title_text => self.titleize,
          :filename_text => self.urn_attribute
        )
    
      self.set_xml_content(rewritten_xml, :comment => "Update header to reflect new identifier '#{self.name}'")
    end
  end
  
  def update_commentary(line_id, reference, comment_content = '', original_item_id = '', delete_comment = false)
    rewritten_xml =
      JRubyXML.apply_xsl_transform(
        JRubyXML.stream_from_string(
          EpiCTSIdentifier.preprocess(self.xml_content)),
        JRubyXML.stream_from_file(File.join(Rails.root,
          %w{data xslt ddb update_commentary.xsl})),
        :line_id => line_id,
        :reference => reference,
        :content => comment_content,
        :original_item_id => original_item_id,
        :delete_comment => (delete_comment ? 'true' : '')
      )
    
    self.set_xml_content(rewritten_xml, :comment => '')
  end
  
  def update_frontmatter_commentary(commentary_content, delete_commentary = false)
    rewritten_xml =
      JRubyXML.apply_xsl_transform(
        JRubyXML.stream_from_string(
          EpiCTSIdentifier.preprocess(self.xml_content)),
        JRubyXML.stream_from_file(File.join(Rails.root,
          %w{data xslt ddb update_frontmatter_commentary.xsl})),
        :content => commentary_content,
        :delete_commentary => (delete_commentary ? 'true' : '')
      )
    
    self.set_xml_content(rewritten_xml, :comment => '')
  end
  
  
  # Override REXML::Attribute#to_string so that attributes are defined
  # with double quotes instead of single quotes
  REXML::Attribute.class_eval( %q^
    def to_string
      %Q[#@expanded_name="#{to_s().gsub(/"/, '&quot;')}"]
    end
  ^ )
    
  def preview parameters = {}, xsl = nil
    ## Manuscripts can be quite big - for these we 
    ## should ask the user to specify which passage they want to preview
    if (self.xml_content.size < MAX_PREVIEW_SIZE)
      JRubyXML.apply_xsl_transform(
        JRubyXML.stream_from_string(self.xml_content),
        JRubyXML.stream_from_file(File.join(Rails.root,
          xsl ? xsl : self.preview_xslt)),
          parameters)
    else
      # TODO interface for selecting and previewing passages
      '<div class="todo">Text should be previewed here but it is too large. An upcoming release will offer the ability to preview selected passages.</div>' 
    end  
  end
  
  def preview_xslt
    %w{data xslt perseus epidoc_preview.xsl}
  end
  
end
