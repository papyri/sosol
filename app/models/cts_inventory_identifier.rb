# Identifier for CTS Inventory Metadata
class CTSInventoryIdentifier < Identifier
  require 'json'
  
  attr_accessor :configuration

  PATH_PREFIX = 'CTS_XML_TextInventory'
  FRIENDLY_NAME = "TextInventory"
  IDENTIFIER_NAMESPACE = 'textinventory'

  def is_valid_xml?(content = nil)
    return true
  end
  
  def self.new_from_template(publication,inventory,parent,urn)
    temp_name = parent.dup
    temp_name.sub!(/edition/,'textinventory')
    temp_id = self.new(:name => temp_name)
    temp_id.publication = publication
    temp_id.title = "TextInventory for #{urn}"
    initial_content = CTS::CTSLib.proxyGetCapabilities(inventory) 
    temp_id.set_xml_content(initial_content,:comment => 'Inventory from CTS Repository')
    temp_id.save!
    return temp_id
  end
  
  def configuration 
    return @configuration
  end

  def update_version_label(urnStr,title,lang)
     urn = CTS::CTSLib.urnObj(urnStr)
     rewritten_xml = JRubyXML.apply_xsl_transform(
       JRubyXML.stream_from_string(self.xml_content),
       JRubyXML.stream_from_file(File.join(Rails.root,
       %w{data xslt cts update_version_title.xsl})), 
       :textgroup => urn.getTextGroup(true), :work => urn.getWork(true), :version => urn.getVersion(true), :label => title , :lang => lang
      )
     self.set_xml_content(rewritten_xml, :comment => "Update version label for #{urnStr}")
  end  

  def add_edition(identifier)
    # TODO we should enable specification of citation scheme   
    urn = CTS::CTSLib.urnObj(identifier.urn_attribute)
    rewritten_xml = JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(self.xml_content),
      JRubyXML.stream_from_file(File.join(Rails.root,
      %w{data xslt cts add_edition.xsl})), 
      :textgroup => urn.getTextGroup(true), 
      :work => urn.getWork(true), 
      :edition => urn.getVersion(true), 
      :label => identifier.title,
      :filepath => identifier.to_path)
    self.set_xml_content(rewritten_xml, :comment => "Added Edition #{identifier.urn_attribute}")
  end

  def add_translation(edition, identifier)
     editionUrn = CTS::CTSLib.urnObj(edition)
     translationUrn = CTS::CTSLib.urnObj(identifier.urn_attribute)
     Rails.logger.info("ADDING EDITION #{editionUrn.getTextGroup(true)} #{editionUrn.getWork(true)} #{editionUrn.getVersion(true)} #{translationUrn.getVersion(true)}")
     rewritten_xml = JRubyXML.apply_xsl_transform(
       JRubyXML.stream_from_string(self.xml_content),
       JRubyXML.stream_from_file(File.join(Rails.root,
       %w{data xslt cts add_translation.xsl})), 
       :textgroup => editionUrn.getTextGroup(true), 
       :work => editionUrn.getWork(true), 
       :edition => editionUrn.getVersion(true), 
       :translation => translationUrn.getVersion(true), 
       :lang => identifier.lang, 
       :label => identifier.title,
       :filepath => identifier.to_path)
     self.set_xml_content(rewritten_xml, :comment => "Added Translation #{identifier.urn_attribute}")
  end

  def remove_translation(identifier)
     urn = CTS::CTSLib.urnObj(identifier.urn_attribute)
     rewritten_xml = JRubyXML.apply_xsl_transform(
       JRubyXML.stream_from_string(self.xml_content),
       JRubyXML.stream_from_file(File.join(Rails.root,
       %w{data xslt cts delete_translation.xsl})), 
       :textgroup => urn.getTextGroup(true), 
       :work => urn.getWork(true), 
       :translation => urn.getVersion(true))
     self.set_xml_content(rewritten_xml, :comment => "Removed Translation #{identifier.urn_attribute}")
  end

  def preview parameters = {}, xsl = nil
    "<pre>" + self.parse_inventory()['citations'].inspect + "</pre>"
  end

  def parentIdentifier 
    return 
      TeiCTSIdentifier.find_by_publication_id(self.publication.id, :limit => 1) ||
      EpiCTSIdentifier.find_by_publication_id(self.publication.id, :limit => 1)
  end
  
  def parse_inventory(urnStr=nil)
    atts = {}
    if urnStr.nil?
      urnStr = self.title
      urnStr.sub!(/TextInventory for /,'')
      # hack for backwards compatibility with text inventory idenfiers whose titles
      # were missing the urn:cts bit...
      unless urnStr =~ /^urn:cts:/
        urnStr = "urn:cts:#{urnStr}"
      end
    end
    urn = CTS::CTSLib.urnObj(urnStr)
    
    atts['worktitle'] = { 'eng' =>
          JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(self.xml_content),
          JRubyXML.stream_from_file(File.join(Rails.root,
              %w{data xslt cts work_title.xsl})), 
              :textgroup => urn.getTextGroup(true), :work => urn.getWork(true))
    }
    atts['versiontitle'] = { 'eng' =>
       JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(self.xml_content),
          JRubyXML.stream_from_file(File.join(Rails.root,
            %w{data xslt cts version_title.xsl})), 
            :textgroup => urn.getTextGroup(true), :work => urn.getWork(true), :version => urn.getVersion(true) )
    }
    atts['citations'] = JSON.parse(
          JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(self.xml_content),
          JRubyXML.stream_from_file(File.join(Rails.root,
              %w{data xslt cts inventory_citation_to_json.xsl})), 
              :e_textgroup => urn.getTextGroup(true), :e_work => urn.getWork(true), :e_edition => urn.getVersion(true)
    ))
    #if (self[:citations].has_key? 'Error')
    #  raise "Invalid Citation Information in Inventory"
    #end 
    return atts
  end
  
  def to_path
    return self.class::PATH_PREFIX + "/" + self.name + "/ti.xml"
  end
  
  def self.is_visible 
    return false
  end

  def download_file_name
    'cts-inventory.xml'
  end

  def schema
    'http://chs.harvard.edu/xmlns/cts3/ti'
  end
end
