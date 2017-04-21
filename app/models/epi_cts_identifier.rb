# encoding: utf-8

class EpiCTSIdentifier < CTSIdentifier   
  require 'json'
  
  PATH_PREFIX = 'CTS_XML_EpiDoc'
  
  FRIENDLY_NAME = "Transcription Text (EpiDoc)"
  
  IDENTIFIER_NAMESPACE = 'epigraphy_edition'
  
  XML_VALIDATOR = JRubyXML::EpiDocP5Validator
  XML_CITATION_PREPROCESSOR = 'preprocess_epi_passage.xsl'

  # This is a somewhat arbitrary size restriction 
  # at some point would be nice to do something more intelligent  
  MAX_PREVIEW_SIZE = 500000

  BROKE_LEIDEN_MESSAGE = "Broken Leiden+ below saved to come back to later:\n"

  # defined in vendor/plugins/rxsugar/lib/jruby_helper.rb
  acts_as_leiden_plus

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
      JRubyXML.stream_from_file(File.join(Rails.root,
        %w{data xslt cts preprocess.xsl})))
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

  # this is a hack to allow us to try leiden+ out on a per document basis
  # it looks for a normalization element in the editorialDecl of the teiHeader
  # with a @source attribute set to "leidenplus"
  def allow_leiden
    allow_leiden = false
    # Disabling due to performance concerns and lack of interest.
    # If feature is desired we need a better way to enable per document
    #xml = REXML::Document.new(content).root
    #REXML::XPath.each(xml,"/tei:TEI/tei:teiHeader/tei:encodingDesc/tei:editorialDecl/tei:normalization",{'tei' => 'http://www.tei-c.org/ns/1.0'}) { |n|
    #  if ! n.attributes['source'].nil? && n.attributes['source'] == 'leidenplus'
    #     allow_leiden = true
    #  end
    #}
    return allow_leiden
  end

  def agent
    # we want to cache this call because (1) it's not likely to change often 
    # and (2) as we may call it in a request that subsequently retrieves the
    # document for display or editing, it causes a redundant fetch from git
    # which is especially costly on large files
    # caching with the publication cache_key ensures that it will be 
    # re-fetched whenever the document changes
    Rails.cache.fetch("#{self.publication.cache_key}/#{self.id}/agent") do
      xml = REXML::Document.new(content).root
      agent = REXML::XPath.first(xml,"/tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:distributor",{'tei' => 'http://www.tei-c.org/ns/1.0'})
      unless agent.nil?
        AgentHelper::agent_of(agent.text)
      end
    end
  end


  # now that we cache data, we need to allow for it to be explicitly cleared as
  # well, although if we used a external cache like memcached it could be handled
  # there
  def clear_cache
    Rails.cache.delete("#{self.publication.cache_key}/#{self.id}/agent")
    super()
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
            JRubyXML.stream_from_file(File.join(Rails.root, transform)),
             'urn' => self.urn_attribute,
             'reviewers' => signed_off_messages.join(',')
          )
        end
        agent_client.post_content(content)
        # we want to return false here because the identifier itself
        # wasn't modified
        return false
      end
    rescue Exception => e
      Rails.logger.error(e) 
      Rails.logger.error(e.backtrace) 
      raise "Unable to send finalization copy to agent #{agent.inspect}"
    end
  end

  # Extracts 'Leiden+ that will not parse' from Text XML file if it was saved by the user
  #
  # - *Args*  :
  #   - +original_xml+ -> REXML::Document/XML to look for broken Leiden+ in. If nil, will retrieve from the 
  #     repository based on the the Text Identifier currently processing
  # - *Returns* :
  #   - +nil+ - if broken Leiden+ is not in the XML file
  #   - +brokeleiden+ - the broken Leiden+ extracted from the XML
  def get_broken_leiden(original_xml = nil)
    original_xml_content = original_xml || REXML::Document.new(self.xml_content)
    brokeleiden_path = '/TEI/text/body/div[@type = "edition"]/div[@subtype = "brokeleiden"]/note'
    brokeleiden_here = REXML::XPath.first(original_xml_content, brokeleiden_path)
    if brokeleiden_here.nil?
      return nil
    else
      brokeleiden = brokeleiden_here.get_text.value
      
      return brokeleiden.sub(/^#{Regexp.escape(BROKE_LEIDEN_MESSAGE)}/,'')
    end
  end

  # - Retrieves the XML for the the Text identifier currently processing from the repository
  # - Applies preprocessing and cleanup via XSLT
  # - Checks if XML contains 'broken Leiden+"
  #
  # - *Returns* :
  #   - +nil+ - if broken Leiden+ is in the XML file
  #   - +transformed+ - Leiden+ transformed from the XML via Xsugar
  def leiden_plus
    original_xml = EpiCTSIdentifier.preprocess(self.xml_content)
    
    # strip xml:id from lb's
    original_xml = JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(original_xml),
      JRubyXML.stream_from_file(File.join(Rails.root,
        %w{data xslt ddb strip_lb_ids.xsl})))
    
    original_xml_content = REXML::Document.new(original_xml)

    # if XML does not contain broke Leiden+ send XML to be converted to Leiden+ and return that
    # otherwise, return nil (client can then get_broken_leiden)
    if get_broken_leiden(original_xml_content).nil?
      # get div type=edition from XML in string format for conversion
      abs = EpiCTSIdentifier.get_div_edition(original_xml).to_s
      # transform XML to Leiden+ 
      transformed = EpiCTSIdentifier.xml2nonxml(abs)
      
      return transformed
    else
      return nil
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
    xml_content = self.leiden_plus_to_xml(
      pp_leiden)
    # commit xml to repo
    self.set_xml_content(xml_content, :comment => comment)
  end

  # Override REXML::Attribute#to_string so that attributes are defined
  # with double quotes instead of single quotes
  REXML::Attribute.class_eval( %q^
    def to_string
      %Q[#@expanded_name="#{to_s().gsub(/"/, '&quot;')}"]
    end
  ^ )
  
  # - Transforms Leiden+ to XML
  # - Retrieves the current version of XML for this EpiCTSIdentifier
  # - Replace the 'div type = "edition"' with the newly transformed XML
  # 
  # - *Args*  :
  #   - +content+ -> the Leiden+ to transform into XML
  # - *Returns* :
  #   -  +modified_xml_content+ - XML with the 'div type = "edition"' containing the newly transformed XML
  def leiden_plus_to_xml(content)

    # transform the Leiden+ to XML
    nonx2x = EpiCTSIdentifier.nonxml2xml(content)
    
    #remove namespace from XML returned from XSugar
    nonx2x.sub!(/ xmlns:xml="http:\/\/www.w3.org\/XML\/1998\/namespace"/,'')
      
    transformed_xml_content = REXML::Document.new(
      nonx2x)
      
    # fetch the original content
    original_xml_content = REXML::Document.new(self.xml_content)
    
    #deletes div type=edition in current XML which includes <div> with subtype=brokeLeiden if it exists, 
    #all <div> type=textpart and/or <ab> tags
    #the complete <div> type=edition will be replaced with new transformed_xml_content
    original_xml_content.delete_element('/TEI/text/body/div[@type = "edition"]')
    
    #delete \n left after delete div edition so not keep adding newlines to XML content
    original_xml_content.delete_element('/TEI/text/body/node()[last()]')
    
    modified_abs = transformed_xml_content.elements['/']
    
    original_edition =  original_xml_content.elements['/TEI/text/body']
    
    # put new div type=edition content in
    original_edition.add_text modified_abs[0]
    
    # write back to a string and return it to calling 
    modified_xml_content = ''
    original_xml_content.write(modified_xml_content)
    return modified_xml_content
  end
  
  # - Retrieves the current version of XML for this EpiCTSIdentifier
  # - Delete/Add the 'div type = "edition" subtype = "brokeleiden"' that contains the broken Leiden+
  # - Saves the XML containing the 'broken Leiden_' to the repository
  # 
  # - *Args*  :
  #   - +brokeleiden+ -> the Leiden+ that will not transform to save in the XML
  #   - +commit_comment+ -> the comment from the user to attach to this repository commit and put 
  def save_broken_leiden_plus_to_xml(brokeleiden, commit_comment = '')
    # fetch the original content
    original_xml_content = REXML::Document.new(self.xml_content)
    #deletes XML with broke Leiden+ if it exists already so can add with updated data
    original_xml_content.delete_element('/TEI/text/body/div[@type = "edition"]/div[@subtype = "brokeleiden"]')
    #set in XML where to add new div tag to contain broken Leiden+ and add it
    basepath = '/TEI/text/body/div[@type = "edition"]'
    add_node_here = REXML::XPath.first(original_xml_content, basepath)
    add_node_here.add_element 'div', {'type'=>'edition', 'subtype'=>'brokeleiden'}
    #set in XML where to add new note tag to contain broken Leiden+ and add it
    basepath = '/TEI/text/body/div[@type = "edition"]/div[@subtype = "brokeleiden"]'
    add_node_here = REXML::XPath.first(original_xml_content, basepath)
    add_node_here.add_element "note"
    #set in XML where to add broken Leiden+ and add it
    basepath = '/TEI/text/body/div[@type = "edition"]/div[@subtype = "brokeleiden"]/note'
    add_node_here = REXML::XPath.first(original_xml_content, basepath)
    brokeleiden = BROKE_LEIDEN_MESSAGE + brokeleiden
    add_node_here.add_text brokeleiden
    
    # write back to a string
    modified_xml_content = ''
    original_xml_content.write(modified_xml_content)
    
    # commit xml to repo
    self.set_xml_content(modified_xml_content, :comment => commit_comment)
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
    preprocessed_leiden.tr!("\t",'')

    # convert multiple underdots (\u0323) to a single underdot
    underdot = [0x323].pack('U')
    preprocessed_leiden.gsub!(/#{underdot}+/,underdot)
    
    # consistent LT symbol (<)
    # \u2039 \u2329 \u27e8 \u3008 to \u003c')
    preprocessed_leiden.gsub!(/[‹〈⟨〈]{1}/,'<')
    
    # consistent GT symbol (>)
    # \u203a \u232a \u27e9 \u3009 to \u003e')
    preprocessed_leiden.gsub!(/[›〉⟩〉]{1}/,'>')
    
    # consistent Left square bracket (〚)
    # \u27e6 to \u301a')
    preprocessed_leiden.gsub!(/⟦/,'〚')
    
    # consistent Right square bracket (〛)
    # \u27e7 to \u301b')
    preprocessed_leiden.gsub!(/⟧/,'〛')
    
    # consistent macron (¯)
    # \u02c9 to \u00af')
    preprocessed_leiden.gsub!(/ˉ/,'¯')
    
    # consistent hyphen in linenumbers (-)
    # immediately preceded by a period 
    # \u2010 \u2011 \u2012 \u2013 \u2212 \u10191 to \u002d')
    preprocessed_leiden.gsub!(/\.{1}[‐‑‒–−𐆑]{1}/,'.-')
    
    # consistent hyphen in gap ranges (-)
    # between 2 numbers 
    # \u2010 \u2011 \u2012 \u2013 \u2212 \u10191 to \u002d')
    preprocessed_leiden.gsub!(/(\d+)([‐‑‒–−𐆑]{1})(\d+)/,'\1-\3')

    # convert greek perispomeni \u1fc0 into combining greek perispomeni \u0342
    combining_perispomeni = [0x342].pack('U')
    preprocessed_leiden.gsub!(/#{[0x1fc0].pack('U')}/,combining_perispomeni)

    # normalize to normalized form C
    preprocessed_leiden = ActiveSupport::Multibyte::Chars.new(preprocessed_leiden).normalize(:c).to_s
    
    return preprocessed_leiden
  end

  # @overrides Identifier#schema
  def schema
    'http://www.stoa.org/epidoc/schema/latest/tei-epidoc.rng'
  end 

end
