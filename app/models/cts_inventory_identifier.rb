# Identifier for CTS Inventory Metadata
class CTSInventoryIdentifier < Identifier
  require 'json'

  attr_accessor :configuration

  PATH_PREFIX = 'CTS_XML_TextInventory'.freeze
  FRIENDLY_NAME = 'TextInventory'.freeze
  IDENTIFIER_NAMESPACE = 'textinventory'.freeze

  def is_valid_xml?(_content = nil)
    true
  end

  def self.new_from_template(publication, inventory, parent, urn)
    temp_name = parent.dup
    temp_name.sub!(/edition/, 'textinventory')
    temp_id = new(name: temp_name)
    temp_id.publication = publication
    temp_id.title = "TextInventory for #{urn}"
    initial_content = CTS::CTSLib.proxyGetCapabilities(inventory)
    temp_id.set_xml_content(initial_content, comment: 'Inventory from CTS Repository')
    temp_id.save!
    temp_id
  end

  attr_reader :configuration

  def preview(_parameters = {}, _xsl = nil)
    "<pre>#{parse_inventory['citations'].inspect}</pre>"
  end

  def parentIdentifier
    return
    TeiCTSIdentifier.find_by(publication_id: publication.id) ||
      EpiCTSIdentifier.find_by(publication_id: publication.id)
  end

  def parse_inventory
    atts = {}
    urnStr = title
    urnStr.sub!(/TextInventory for/, 'urn:cts:')
    urn = CTS::CTSLib.urnObj(urnStr)

    atts['worktitle'] = { 'eng' =>
          JRubyXML.apply_xsl_transform(
            JRubyXML.stream_from_string(xml_content),
            JRubyXML.stream_from_file(File.join(Rails.root,
                                                %w[data xslt cts work_title.xsl])),
            textgroup: urn.getTextGroup(true), work: urn.getWork(true)
          ) }
    atts['versiontitle'] = { 'eng' =>
       JRubyXML.apply_xsl_transform(
         JRubyXML.stream_from_string(xml_content),
         JRubyXML.stream_from_file(File.join(Rails.root,
                                             %w[data xslt cts version_title.xsl])),
         textgroup: urn.getTextGroup(true), work: urn.getWork(true), version: urn.getVersion(true)
       ) }
    atts['citations'] = JSON.parse(
      JRubyXML.apply_xsl_transform(
        JRubyXML.stream_from_string(xml_content),
        JRubyXML.stream_from_file(File.join(Rails.root,
                                            %w[data xslt cts inventory_citation_to_json.xsl])),
        e_textgroup: urn.getTextGroup(true), e_work: urn.getWork(true), e_edition: urn.getVersion(true)
      )
    )
    # if (self[:citations].has_key? 'Error')
    #  raise "Invalid Citation Information in Inventory"
    # end
    atts
  end

  def to_path
    "#{self.class::PATH_PREFIX}/#{name}/ti.xml"
  end

  def self.is_visible
    false
  end
end
