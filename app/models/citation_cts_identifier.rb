class CitationCTSIdentifier < CTSIdentifier   
  
  PATH_PREFIX = 'CTS_XML_CITATIONS'
  IDENTIFIER_NAMESPACE = 'citation'
  FRIENDLY_NAME = "Citation Text"
  EDIT_ARTIFACT = true
  
  XML_VALIDATOR = JRubyXML::TEIAPSGValidator
  
  def related_text
    self.publication.identifiers.select{|i| i.class == TeiCTSIdentifier}.last
  end
  
  
  def self.new_from_template(publication,a_inventory,passage_urn,pubtype)    
    document_path = a_inventory + "/" + CTS::CTSLib.pathForUrn(passage_urn,pubtype)
    new_identifier = self.new(:name => document_path)
    new_identifier.publication = publication
    # TODO look at reason for int param to getPassage --- seems wrong
    new_identifier.title = CTS::CTSLib.urnObj("urn:cts:#{passage_urn}").getPassage(100)
    new_identifier.save!
    begin
      uuid = publication.id.to_s + passage_urn.gsub(':','_')
      inventory = new_identifier.related_text.inventory
      document = new_identifier.related_text.content
      passage_xml = CTS::CTSLib.proxyGetPassage(inventory,document,new_identifier.urn_attribute,uuid) 
      new_identifier.set_xml_content(passage_xml, :comment => "extracted passage")
      return new_identifier
    rescue Exception => e
      new_identifier.destroy
      raise e
    end
  end
    
  def before_commit(content)
    #begin
    #  TeiCitationCTSIdentifier.preprocess(content)
    #rescue
    #  raise "Invalid Passage XML"
    #else
      return content
    #end
  end
  
  def self.preprocess(content)
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(content),
      JRubyXML.stream_from_file(File.join(RAILS_ROOT,
        %w{data xslt cts validate_passage.xsl})))
  end
  
  # Override REXML::Attribute#to_string so that attributes are defined
  # with double quotes instead of single quotes
  REXML::Attribute.class_eval( %q^
    def to_string
      %Q[#@expanded_name="#{to_s().gsub(/"/, '&quot;')}"]
    end
  ^ )
 
  
  def preview parameters = {}, xsl = nil
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(self.xml_content),
      JRubyXML.stream_from_file(File.join(RAILS_ROOT,
        xsl ? xsl : %w{data xslt pn start-div-portlet_perseus.xsl})),
        parameters)
  end
  
  # NOTE not currently called, but should be from publication.tally_votes
  def result_action_approve
    # what we want to do:
    # merge passage back into parent text
    # send the parent text for review
    # passage itself doesn't get finalized
    # archive? the passage

    document = self.related_text.content
    updated = CTS::CTSLib.proxyPutPassage(self.content,self.inventory,self.related_text.content,self.urn_attribute,get_recent_commit_sha())
    self.related_text.set_xml_content(updated,:comment =>'merged updated passage #{self.urn_attribute}') 
    self.status = "archived"
  end
  
end
