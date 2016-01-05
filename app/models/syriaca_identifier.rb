# encoding: utf-8

# - Sub-class of Identifier
# - Includes acts_as_leiden_plus defined in vendor/plugins/rxsugar/lib/jruby_helper.rb
class SyriacaIdentifier < Identifier  
  PATH_PREFIX = 'Syriaca_Data'
  
  FRIENDLY_NAME = "Syriaca Gazetter"
  
  IDENTIFIER_NAMESPACE = 'http://syriaca.org'
  TEMPORARY_COLLECTION = 'place'
  
  XML_VALIDATOR = JRubyXML::SyriacaGazetteerValidator
  
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

    return sprintf("#{self::IDENTIFIER_NAMESPACE}/#{self::TEMPORARY_COLLECTION}/%04d;%04d",
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
        xsl ? xsl : %w{data xslt syriaca preview.xsl})),
        parameters)
  end
  
end
