class HGVTransIdentifier < HGVIdentifier
  PATH_PREFIX = 'HGV_trans_EpiDoc'
  IDENTIFIER_NAMESPACE = 'hgvtrans'
  
  XML_VALIDATOR = JRubyXML::EpiDocP5Validator
  
  FRIENDLY_NAME = "Translation"
  
  BROKE_LEIDEN_MESSAGE = "Broken Leiden+ below saved to come back to later:\n"
  
  # defined in vendor/plugins/rxsugar/lib/jruby_helper.rb
  acts_as_translation
  
  
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
  
  def id_attribute
    return "hgv-TEMP"
  end
  
  def n_attribute
    ddb = DDBIdentifier.find_by_publication_id(self.publication.id, :limit => 1)
    return ddb.n_attribute
  end
  
  def xml_title_text
    return " HGVTITLE (DDBTITLE) "
  end
      
	def is_valid?(content = nil)
  	#FIXME added here since trans is not P5 validable yet
    return true
  end
  
  def self.new_from_template(publication)
    new_identifier = super(publication)
    
    new_identifier.stub_text_structure('en')
    
    return new_identifier
  end
  
  def related_text
    self.publication.identifiers.select{|i| (i.class == DDBIdentifier) && !i.is_reprinted?}.last
  end
  
  def stub_text_structure(lang)
    translation_stub_xsl =
      JRubyXML.apply_xsl_transform(
        JRubyXML.stream_from_string(self.related_text.content),
        JRubyXML.stream_from_file(File.join(RAILS_ROOT,
          %w{data xslt translation ddb_to_translation_xsl.xsl}))
      )
    
    rewritten_xml =
      JRubyXML.apply_xsl_transform(
        JRubyXML.stream_from_string(self.content),
        JRubyXML.stream_from_string(translation_stub_xsl),
        :lang => 'en'
      )
    
    self.set_xml_content(rewritten_xml, :comment => "Update translation with stub for @xml:lang='#{lang}'")
  end
  
  def preview
      JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(self.xml_content),
      JRubyXML.stream_from_file(File.join(RAILS_ROOT,
        %w{data xslt pn start-divtrans-portlet.xsl})))
  end
  
  
  
  def leiden_trans
    repo_xml = xml_content
    repo_xml_work = REXML::Document.new(repo_xml)
    body = HGVTransIdentifier.get_body(repo_xml)
    #return body

      # transform XML to Leiden Trans 
      transformed = HGVTransIdentifier.xml2nonxml(body.to_s) #via jrubyHelper
      
      return transformed
      
=begin    
    basepath2 = '/TEI/text/body/div[@type = "edition"]/div[@subtype = "brokeleiden"]/note'
    brokeleiden_here = REXML::XPath.first(repo_xml_work, basepath2)
    #if XML does not contain broke Leiden+ send XML to be converted to Leiden+ and display that
    #otherwise, get broke Leiden+ and display that
    if brokeleiden_here == nil
      abs = DDBIdentifier.preprocess_abs(
        DDBIdentifier.get_abs_from_edition_div(repo_xml))
      # transform XML to Leiden+ 
      transformed = DDBIdentifier.xml2nonxml(abs)
      
      return transformed
    else
      #get the broke Leiden+
      brokeleiden = brokeleiden_here.get_text.value
      
      return brokeleiden.sub(/^#{Regexp.escape(BROKE_LEIDEN_MESSAGE)}/,'')
    end
=end
  end
  
  # Returns a String of the SHA1 of the commit
  def set_leiden_translation_content(leiden_translation_content, comment)
    # transform back to XML
    xml_content = self.leiden_translation_to_xml(leiden_translation_content)
    # commit xml to repo
    self.set_xml_content(xml_content, :comment => comment)
  end
  
  
  def leiden_translation_to_xml(content)
    
    # transform the Leiden Translation to XML
    nonx2x = HGVTransIdentifier.nonxml2xml(content)
        
    nonx2x.sub!(/ xmlns:xml="http:\/\/www.w3.org\/XML\/1998\/namespace"/,'')
    transformed_xml_content = REXML::Document.new(nonx2x)
    
    puts nonx2x
    puts transformed_xml_content.to_s
    # fetch the original content
    original_xml_content = REXML::Document.new(self.xml_content)
    
    #rip out the body so we can replace it with the new data
    original_xml_content.delete_element('/TEI/text/body')
    
    #add the new data
    original_xml_content.elements.each('/TEI/text') { |text_element| text_element.add_element(transformed_xml_content) }
    
 
    # write back to a string
    modified_xml_content = ''
    original_xml_content.write(modified_xml_content)
    return modified_xml_content
  end
  
  
  
  
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
