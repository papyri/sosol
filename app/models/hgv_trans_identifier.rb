# encoding: utf-8
# - Sub-class of HGVIdentifier
# - Includes acts_as_translation defined in vendor/plugins/rxsugar/lib/jruby_helper.rb
class HGVTransIdentifier < HGVIdentifier
  PATH_PREFIX = 'HGV_trans_EpiDoc'
  IDENTIFIER_NAMESPACE = 'hgvtrans'
  
  FRIENDLY_NAME = "Translation"
  
  BROKE_LEIDEN_MESSAGE = "Broken Leiden+ below saved to come back to later:\n"
  
  # defined in vendor/plugins/rxsugar/lib/jruby_helper.rb
  acts_as_translation
  
  # Returns file path to Translation XML - e.g. HGV_trans_EpiDoc/8881.xml
  def to_path
    if name =~ /#{self.class::TEMPORARY_COLLECTION}/
      return self.temporary_path
    else
      path_components = [ PATH_PREFIX ]
      # assume the name is e.g. hgv2302zzr
      trimmed_name = self.to_components.last # 2302zzr

      hgv_xml_path = trimmed_name + '.xml'

      # HGV_trans_EpiDoc uses a flat hierarchy
      path_components << hgv_xml_path

      # e.g. HGV_trans_EpiDoc/2302zzr.xml
      return File.join(path_components)
    end
  end
  
  # Returns value for 'id' attribute in Translation template
  def id_attribute
    return "hgv-TEMP"
  end
  
  # Returns value for 'n' attribute in Translation template
  def n_attribute
    ddb = DDBIdentifier.find_by_publication_id(self.publication.id, :limit => 1)
    return ddb.n_attribute
  end
  
  # Returns value for 'title' attribute in Translation template
  def xml_title_text
    return " HGVTITLE (DDBTITLE) "
  end
  
  # Create empty, default Translation XML file based on the format of the DDB Text file (div's, ab's, etc.)
  # - *Args*  :
  #   - +publication+ -> the publication the new translation is a part of
  # - *Returns* :
  #   - new translation identifier
  def self.new_from_template(publication)
    if self.related_text.nil?
      raise 'No related text to create translation from—this error may occur because the only text associated with this publication is a reprint stub.'
      return nil
    end
    new_identifier = super(publication)
    
    new_identifier.stub_text_structure('en')
    
    return new_identifier
  end
  
  # Returns the 'last' DDB Text identifier that is not a reprint in this tranlsations publication
  def related_text
    self.publication.identifiers.select{|i| (i.class == DDBIdentifier) && !i.is_reprinted?}.last
  end
  
  # Place any actions you always want to perform on translation identifier content prior to it being committed in this method
  # - *Args*  :
  #   - +content+ -> Translation XML as string
  def before_commit(content)
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(content),
      JRubyXML.stream_from_file(File.join(Rails.root,
        %w{data xslt translation preprocess.xsl}))
    )
  end
  
  # Checks for existence of a specific language translation
  # - *Args*  :
  #   - +lang+ -> the language you are checking for (language codes defined in translation helper)
  # - *Returns* :
  #   - true/false
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
  
  # Stub in Translation XML for a specific based on the format of the DDB Text file (div's, ab's, etc) and saves it
  # in the repository
  # - *Args*  :
  #   - +lang+ -> the new language to add (used in 'xml:lang' attribute)
  def stub_text_structure(lang)
    translation_stub_xsl =
      JRubyXML.apply_xsl_transform(
        JRubyXML.stream_from_string(self.related_text.content),
        JRubyXML.stream_from_file(File.join(Rails.root,
          %w{data xslt translation ddb_to_translation_xsl.xsl}))
      )
    
    rewritten_xml =
      JRubyXML.apply_xsl_transform(
        JRubyXML.stream_from_string(self.content),
        JRubyXML.stream_from_string(translation_stub_xsl),
        #:lang => 'en'
        #assumed that hard coded 'en' is remnant and should be
        :lang => lang
      )
      
    
    self.set_xml_content(rewritten_xml, :comment => "Update translation with stub for @xml:lang='#{lang}'")
  end
  
  # Processing needed after user performs the 'rename' function during finalization.  Performed using XSLT and then
  # saves it in the repository
  def after_rename(options = {})
    if options[:update_header]
      related_hgv = self.publication.identifiers.collect{|i| i.to_components.last if i.class == HGVMetaIdentifier}.compact
      related_ddb = self.publication.identifiers.collect{|i| i.to_components.last if i.class == DDBIdentifier}.compact
      rewritten_xml =
        JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(content),
          JRubyXML.stream_from_file(File.join(Rails.root,
            %w{data xslt translation update_header.xsl})),
          :filename_text => self.to_components.last,
          :HGV_text => related_hgv.join(' '),
          :DDB_text => related_ddb.join(' '),
          :TM_text => related_hgv.collect{|h| h.gsub(/\D/,'')}.uniq.join(' '),
          :title_text => NumbersRDF::NumbersHelper::identifier_to_title([NumbersRDF::NAMESPACE_IDENTIFIER,HGVIdentifier::IDENTIFIER_NAMESPACE,self.to_components.last].join('/')),
          :reprint_from_text => options[:set_dummy_header] ? options[:original].title : '',
          :reprint_ref_attribute => options[:set_dummy_header] ? options[:original].to_components.last : ''
        )
    
      self.set_xml_content(rewritten_xml, :comment => "Update header to reflect new identifier '#{self.name}'")
    end
  end
  
  # - Retrieves the current version of XML for this Translation identifier
  # - Processes XML with preview.xsl XSLT
  # 
  # - *Returns* :
  #   -  Preview HTML
  def preview
      parameters = {"edn-structure" => "ddbdp",
        "css-loc" => ""}
      JRubyXML.apply_xsl_transform(
        JRubyXML.stream_from_string(self.xml_content),
        JRubyXML.stream_from_file(File.join(Rails.root,
          %w{data xslt translation preview.xsl})),
          parameters)
  end
  
  # Extracts 'Leiden+ that will not parse' from Translation XML file if it was saved by the user
  #
  # - *Args*  :
  #   - +original_xml+ -> REXML::Document/XML to look for broken Leiden+ in. If nil, will retrieve from the 
  #     repository based on the the Translation Identifier currently processing
  # - *Returns* :
  #   - +nil+ - if broken Leiden+ is not in the XML file
  #   - +brokeleiden+ - the broken Leiden+ extracted from the XML
  def get_broken_leiden(original_xml = nil)
    original_xml_content = original_xml || REXML::Document.new(self.xml_content)
    brokeleiden_path = '/TEI/text/body/div[@type = "translation"]/div[@subtype = "brokeleiden"]/note'
    brokeleiden_here = REXML::XPath.first(original_xml_content, brokeleiden_path)
    if brokeleiden_here.nil?
      return nil
    else
      brokeleiden = brokeleiden_here.get_text.value
      
      return brokeleiden.sub(/^#{Regexp.escape(BROKE_LEIDEN_MESSAGE)}/,'')
    end
  end
  
  # - Retrieves the XML for the the Translation identifier currently processing from the repository
  # - Checks if XML contains 'broken Leiden+"
  #
  # - *Returns* :
  #   - +nil+ - if broken Leiden+ is in the XML file
  #   - +transformed+ - Leiden+ transformed from the XML via Xsugar
  def leiden_trans
    original_xml = self.xml_content
    original_xml_content = REXML::Document.new(original_xml)

    # if XML does not contain broke Leiden send XML to be converted to Leiden and return that
    # otherwise, return nil (client can then get_broken_leiden)
    if get_broken_leiden(original_xml_content).nil?
      body = HGVTransIdentifier.get_body(original_xml)
      
      # transform XML to Leiden+ 
      transformed = HGVTransIdentifier.xml2nonxml(body.join('')).force_encoding('UTF-8') #via jrubyHelper
      
      return transformed
    else
      return nil
    end
  end
  
  # - Transforms Translation Leiden+ to XML
  # - Saves the newly transformed XML to the repository
  # 
  # - *Args*  :
  #   - +leiden_translation_content+ -> the Translation Leiden+ to transform into XML
  #   - +comment+ -> the comment from the user to attach to this repository commit and put in the comment table
  # - *Returns* :
  #   -  a String of the SHA1 of the commit
  # Returns a String of the SHA1 of the commit
  def set_leiden_translation_content(leiden_translation_content, comment)
    # transform back to XML
    xml_content = self.leiden_translation_to_xml(leiden_translation_content)
    # commit xml to repo
    self.set_xml_content(xml_content, :comment => comment)
  end
  
  # - Transforms Translation Leiden+ to XML
  # - Retrieves the current version of XML for this DDBIdentifier
  # - Replace everything after 'body' (div type = "translation") with the newly transformed XML
  # 
  # - *Args*  :
  #   - +content+ -> the Translation Leiden+ to transform into XML
  # - *Returns* :
  #   -  +modified_xml_content+ - XML with the 'div type = "edition"' containing the newly transformed XML
  def leiden_translation_to_xml(content)
    
    # transform the Leiden Translation to XML
    nonx2x = HGVTransIdentifier.nonxml2xml(content)
        
    nonx2x.sub!(/ xmlns:xml="http:\/\/www.w3.org\/XML\/1998\/namespace"/,'')
    transformed_xml_content = REXML::Document.new(nonx2x)
 
    #puts "Leiden+ transform result: #{nonx2x}"
    #puts transformed_xml_content.to_s
    # fetch the original content
    original_xml_content = REXML::Document.new(self.xml_content)
    
    #rip out the body so we can replace it with the new data
    original_xml_content.delete_element('/TEI/text/body')
    
    #add the new data
    original_xml_content.elements.each('/TEI/text') { |text_element| text_element.add_element(transformed_xml_content) }
    
 
    # write back to a string
    modified_xml_content = ''
    original_xml_content.write(modified_xml_content)
    puts modified_xml_content
    return modified_xml_content
  end
  
  # - Retrieves the current version of XML for this Translation identifier
  # - Delete/Add the 'div type = "translation" subtype = "brokeleiden"' that contains the broken Leiden+
  # - Saves the XML containing the 'broken Leiden_' to the repository
  # 
  # - *Args*  :
  #   - +brokeleiden+ -> the Translation Leiden+ that will not transform to save in the XML
  #   - +commit_comment+ -> the comment from the user to attach to this repository commit and put 
  def save_broken_leiden_trans_to_xml(brokeleiden, commit_comment = '')
    # fetch the original content
    original_xml_content = REXML::Document.new(self.xml_content)
    #deletes XML with broke Leiden+ if it exists already so can add with updated data
    original_xml_content.delete_element('/TEI/text/body/div[@type = "translation"]/div[@subtype = "brokeleiden"]')
    #set in XML where to add new div tag to contain broken Leiden+ and add it
    basepath = '/TEI/text/body/div[@type = "translation"]'
    add_node_here = REXML::XPath.first(original_xml_content, basepath)
    add_node_here.add_element 'div', {'type'=>'translation', 'subtype'=>'brokeleiden'}
    #set in XML where to add new note tag to contain broken Leiden+ and add it
    basepath = '/TEI/text/body/div[@type = "translation"]/div[@subtype = "brokeleiden"]'
    add_node_here = REXML::XPath.first(original_xml_content, basepath)
    add_node_here.add_element "note"
    #set in XML where to add broken Leiden+ and add it
    basepath = '/TEI/text/body/div[@type = "translation"]/div[@subtype = "brokeleiden"]/note'
    add_node_here = REXML::XPath.first(original_xml_content, basepath)
    brokeleiden = BROKE_LEIDEN_MESSAGE + brokeleiden
    add_node_here.add_text brokeleiden
    
    # write back to a string
    modified_xml_content = ''
    original_xml_content.write(modified_xml_content)
    
    # commit xml to repo
    self.set_xml_content(modified_xml_content, :comment => commit_comment)
  end
  
  
  
end
