# encoding: utf-8

# - Sub-class of Identifier
# - Includes acts_as_leiden_plus defined in vendor/plugins/rxsugar/lib/jruby_helper.rb
class SyriacaIdentifier < Identifier

  PATH_PREFIX = 'Syriaca_Data'
  FRIENDLY_NAME = "Syriaca Gazetter"
  IDENTIFIER_NAMESPACE = 'http://syriaca.org'
  TEMPORARY_COLLECTION = 'place'
  XML_VALIDATOR = JRubyXML::SyriacaGazetteerValidator
  NS_TEI = "http://www.tei-c.org/ns/1.0"

  #################################
  # Public Class Method Overrides
  #################################

  # @overrides Identifier.next_temporary_identifier
  # to replace hardcoded papyri.info with the IDENTIFIER_NAMESPACE
  # Will only be used in testing because identifier is taken from
  # content in practice.
  # - starts at '1' each year
  # - *Returns* :
  #   - temporary identifier name
  def self.next_temporary_identifier
    year = Time.now.year
    latest = self.find(:all,
                       :conditions => ["name like ?", "#{self::IDENTIFIER_NAMESPACE}/#{self::TEMPORARY_COLLECTION}/#{year}-%"],
                       :order => "name DESC",
                       :limit => 1).first
    if latest.nil?
      # no constructed id's for this year/class
      document_number = 1
    else
      document_number = latest.to_components.last.split('-').last.to_i + 1
    end

    return sprintf("#{self::IDENTIFIER_NAMESPACE}/#{self::TEMPORARY_COLLECTION}/%04d%04d",
                   year, document_number)
  end

  # @overrides Identifier#identifier_from_content
  # to parse the identifier from a supplied gazetteer document
  # - *Args* :
  #   - +content+ -> the supplied content
  # - *Returns*: the identifier, and unchanged content
  def self.identifier_from_content(agent,content)
    xml = REXML::Document.new(content).root
    uri = REXML::XPath.first(xml,'/tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type="URI"]',{"tei" => NS_TEI})
    if (uri)
      uri = uri.text.sub(/\/tei$/,'')
    else
      raise Exception.new("Missing Identifier")
    end
    return uri,content
  end

  ## create a default title for a syriaca identifier
  # @overrides Identifier#create_title
  def self.create_title(uri)
    type, id = uri.split('/')[3..-1]
    "#{type}-#{id}"
  end


  ##################################
  # Public Instance Method Overrides
  ##################################

  # @overrides Identifier#titleize
  # uses name as title
  def titleize
    xml = REXML::Document.new(self.xml_content).root
    title = REXML::XPath.first(xml,'/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[@level="a"]',{"tei" => NS_TEI})
    if title 
      title = title.text();
    else
      title = self.name;
    end
    return title
  end

  # @overrides Identifier#id_attribute
  # Returns value for 'idno' in tei header
  def id_attribute
    "#{self.name}/tei"
  end
  
  # @overrides Identifier#n_attribute
  # Returns value for 'xml:id' attribute in place
  def n_attribute
    type, id = self.to_components[3..-1]
    "#{type}-#{id}"
  end
  
  # @overrides Identifier#xml_title_text
  # Returns value from id_attribute as value for 'title' attribute in Text template
  def xml_title_text
    self.id_attribute
  end

  # @overrides Identifier#to_path
  # Returns file path to XML
  def to_path
    # a syriaca gazetteer identifier looks like
    # http://syriaca.org/place/num
    # identifier.to_components splits on "/"
    type, id = self.to_components[3..-1]
   
    # this will be stored at
    #  Syriaca_Data/place/xxxx.xml
    path_components = [ PATH_PREFIX ]
    path_components << type
    path_components << "#{id}.xml"
    
    return File.join(path_components)
  end

  # @overrides Identifier#after_rename
  def after_rename(options = {})
    raise "Rename not supported"
  end

  # retrieve the remote path for finalization
  # eventually this should be found in the metadata
  # in the identifier contents
  def to_remote_path
    type, id = self.to_components[3..-1]
    "data/places/tei/#{id}.xml"
  end

  # retrieve the remote path for review
  # eventually this should be found in the metadata
  # in the identifier contents or use id_attribute directly
  def to_remote_raw_path
    return "#{self.name}/tei"

  end
  
  # @overrides Identifier#get_catalog_link
  # links to the original gazetteer entry on syriaca
  def get_catalog_link
    ["View at Syriaca.org",self.name]
  end

  # @overrides Identifier#preprocess_for_finalization
  # Posts to Srophe normalization service
  def preprocess_for_finalization(reviewed_by)
    if self.status == 'finalizing-preprocessed'
      return false
    end 
    agent = AgentHelper::agent_of(self.name)
    agent_client = AgentHelper::get_client(agent)
    updated = agent_client.post_content(self.content)
    self.set_xml_content(updated,{:comment => "Preprocessed via #{agent_client.to_s}"})
    self.status = "finalizing-preprocessed" # TODO check this 
    return true
  end
end
