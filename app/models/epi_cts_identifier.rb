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

  def titleize
    # try to get the title from the content
    if self.xml_content
      xml = REXML::Document.new(content).root
      title = REXML::XPath.first(xml, "//tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title", {'tei' => 'http://www.tei-c.org/ns/1.0'})
      unless title.nil? 
        title = title.text
      end
    end
    # otherwise fall back to default behavior for a CTS identifier
    if title.nil? || title == ''
      return super() 
    else
      return title
    end
  end

    
  def before_commit(content)
    EpiCTSIdentifier.preprocess(content)
  end
  
  def self.preprocess(content)
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(content),
      JRubyXML.stream_from_file(File.join(RAILS_ROOT,
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
          JRubyXML.stream_from_file(File.join(RAILS_ROOT,
            %w{data xslt ddb dummyize.xsl}))
        )
      
      original.save!
      self.publication.identifiers << original
      
      dummy_header = self.add_change_desc(dummy_comment_text, self.publication.owner, dummy_header)
      original.set_xml_content(dummy_header, :comment => dummy_comment_text)
            
      # need to do on originals too
      self.relatives.each do |relative|
        original_relative = relative.clone
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
          JRubyXML.stream_from_file(File.join(RAILS_ROOT,
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
        JRubyXML.stream_from_file(File.join(RAILS_ROOT,
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
        JRubyXML.stream_from_file(File.join(RAILS_ROOT,
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
        JRubyXML.stream_from_file(File.join(RAILS_ROOT,
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
  
  def self.parse_docs(content)
    docs = []
    xml = REXML::Document.new(content).root
    formatter = PrettySsime.new
    formatter.compact = true
    formatter.width = 2**32
  
    # retrieve documents, pubtypes and languages
    REXML::XPath.each(xml, "//tei:TEI", {'tei' => 'http://www.tei-c.org/ns/1.0'}) { |doc|
      version = REXML::XPath.first(doc,"tei:text/tei:body/tei:div",{'tei' => 'http://www.tei-c.org/ns/1.0'})
      if (version.nil? || version.attributes['type'].nil? || version.attributes['xml:lang'].nil?)
        raise "Unable to parse doc #{version}"
      end
      lang = version.attributes['xml:lang']    
      modified_xml_content = ''
      formatter.write doc, modified_xml_content
      doc = Hash.new
      doc[:lang] = lang
      doc[:contents] = modified_xml_content
      docs << doc
               
    }
    return docs
  end

  def agent
    xml = REXML::Document.new(content).root
    agent = REXML::XPath.first(xml,"/tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:distributor",{'tei' => 'http://www.tei-c.org/ns/1.0'})
    unless agent.nil?
      agent = AgentHelper::agent_of(agent.text)
    end
    return agent
  end

  # check to see if we have a registered distributor agent, and if so
  # send the finalization copy back to them too
  def preprocess_for_finalization(reviewed_by)
    agent = self.agent
    if agent.nil?
      return
    end
    begin
      agent_client = AgentHelper::get_client(agent)
      unless (agent_client.nil?)
        if (agent[:transformations][:EpiCTSIdentifier])
          signed_off_messages = []
          reviewed_by.each do |m|
            signed_off_messages << m
          end
          transform = agent[:transformations][:EpiCTSIdentifier]
          content = JRubyXML.apply_xsl_transform(
            JRubyXML.stream_from_string(self.content),
            JRubyXML.stream_from_file(File.join(RAILS_ROOT, transform)),
             'urn' => self.urn_attribute,
             'reviewers' => signed_off_messages.join(',')
          )
        end
        agent_client.post_content(content)
      end
    rescue Exception => e
      Rails.logger.error(e) 
      Rails.logger.error(e.backtrace) 
      raise "Unable to send finalization copy to agent #{agent.inspect}"
    end
  end
end
