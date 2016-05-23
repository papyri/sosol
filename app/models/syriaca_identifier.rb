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
  
  # Determines the next 'SoSOL' temporary name for the associated identifier
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

  # Returns value for 'idno' in tei header
  def id_attribute
    "#{self.name}/tei"
  end
  
  # Returns value for 'xml:id' attribute in place
  def n_attribute
    type, id = self.to_components[3..-1]
    "#{type}-#{id}"
  end
  
  # Returns value from id_attribute as value for 'title' attribute in Text template
  def xml_title_text
    self.id_attribute
  end

  # Returns file path to DDB Text XML - e.g. DDB_EpiDoc_XML/bgu/bgu.10/bgu.10.1901.xml
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
  
  def after_rename(options = {})
    raise "Rename not supported"
  end
  
  # - Retrieves the current version of XML for this Identifier
  # - Processes XML with preview.xsl XSLT
  # 
  # - *Returns* :
  #   -  Preview HTML
  def preview parameters = {}, xsl = nil
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(self.xml_content),
      JRubyXML.stream_from_file(File.join(Rails.root,
        xsl ? xsl : %w{data xslt syriaca srophe-app resources xsl tei2html.xsl})),
        parameters)
  end

  def self.api_parse_post_for_identifier(a_post)
    xml = REXML::Document.new(a_post).root
    Rails.logger.info("Parsing #{xml.to_s}")
    uri = REXML::XPath.first(xml,'/tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type="URI"]',{"tei" => NS_TEI})
    if (uri)
      uri.text.sub(/\/tei$/,'')
    else
      raise Exception.new("Missing Identifier")
    end
  end

  def self.api_create(a_publication,a_agent,a_body,a_comment)
    uri = self.api_parse_post_for_identifier(a_body)
    temp_id = self.new(:name => uri)
    temp_id.publication = a_publication 
    temp_id.save!
    temp_id.set_content(a_body, :comment => a_comment, :actor => (a_publication.owner.class == User) ? a_publication.owner.jgit_actor : a_publication.creator.jgit_actor)
    template_init = temp_id.add_change_desc(a_comment)
    temp_id.set_xml_content(template_init, :comment => 'Initializing Content')
    return temp_id
  end

  def self.find_matching_identifiers(match_id,match_user,match_pub)
    publication = nil
    existing_identifiers = []

    possible_conflicts = self.find(:all,
               :conditions => ["name = ?", "#{match_id}"],
               :order => "name DESC")
          
    actual_conflicts = possible_conflicts.select {|pc| 
    begin
        ((pc.publication) && 
          (pc.publication.owner == match_user) && 
          !(%w{archived finalized}.include?(pc.publication.status)) &&
           pc.is_match?(match_pub)
        )
      rescue Exception => e
          Rails.logger.error("Error checking for conflicts #{pc.publication.status} : #{e.backtrace}")
      end
    }
    existing_identifiers += actual_conflicts
    return existing_identifiers
  end

  def titleize
    title = self.name
    return title
  end

  ## create a default title for a syriaca identifier
  def self.create_title(uri)
    type, id = uri.split('/')[3..-1]
    "#{type}-#{id}"
  end

  def get_catalog_link
    return self.name
  end
end
