class HGVMetaIdentifier < HGVIdentifier
  PATH_PREFIX = 'HGV_meta_EpiDoc'
  
  XML_VALIDATOR = JRubyXML::EpiDocP5Validator
  
  FRIENDLY_NAME = "Meta"
  
  def to_path
    # if alternate_name.nil?
      # no alternate name, use SoSOL temporary path
      # return self.temporary_path
    # else
      path_components = [ PATH_PREFIX ]
      # assume the alternate name is e.g. hgv2302zzr
      trimmed_name = self.to_components.last # 2302zzr
      number = trimmed_name.sub(/\D/, '').to_i # 2302

      hgv_dir_number = ((number - 1) / 1000) + 1
      hgv_dir_name = "HGV#{hgv_dir_number}"
      hgv_xml_path = trimmed_name + '.xml'

      path_components << hgv_dir_name << hgv_xml_path

      # e.g. HGV_meta_EpiDoc/HGV3/2302zzr.xml
      return File.join(path_components)
    # end
  end
  
  def id_attribute
    return "hgvTEMP"
  end

  def n_attribute
    ddb = DDBIdentifier.find_by_publication_id(self.publication.id, :limit => 1)
    return ddb.n_attribute
  end
  
  def xml_title_text
    return "Description of document"
  end
  
  def is_valid?(content = nil)
  	#FIXME added here since meta is not P5 validable yet
    return true
  end
  
  def valid_epidoc_attributes
    return [:onDate, :notAfterDate, :notBeforeDate, :textDate, :titleStmt, 
      :publicationTitle, :publicationVolume, :publicationNumbers,
      :tm_nr, :illustrations, :contentText, :other_publications,
      :translations, :bl, :notes, :mentioned_dates_hdr, :mentioned_dates, :material,
      :provenance_ancient_findspot, :provenance_nome,
      :provenance_ancient_region,
      :provenance_modern_findspot, :inventory_number, :planned_for_future_print_release]
  end
  
  def get_or_set_xml_attribute(get_or_set, self_attribute, xml_node, attribute)
    if get_or_set == :get
      self[self_attribute] = xml_node.attributes[attribute]
    elsif get_or_set == :set
      xml_node.attributes[attribute] = self[self_attribute]
    end
  end

  def get_or_set_xml_text(get_or_set, self_attribute, xml_node)
    if get_or_set == :get
      self[self_attribute] = xml_node.text
    elsif get_or_set == :set
      xml_node.text = self[self_attribute]
    end
  end

  def get_epidoc_attributes
    self.get_or_set_epidoc(:get)
    
    # Set nil attrs to empty strings
    valid_epidoc_attributes.each do |this_attr|
        if self[this_attr].nil?
          self[this_attr] = ''
        end
    end
  end
  
  def set_epidoc(attributes_hash, comment)
    self.get_epidoc_attributes_from_params(attributes_hash)
    epidoc = self.get_or_set_epidoc(:set)
    self.set_content(epidoc, :comment => comment)
  end

  def get_epidoc_attributes_from_params(attributes_hash)
    attributes_hash.each_pair do |key, value|
      self[key] = value
    end
  end

  def self.attributes_xpath_hash
    # set base to metadata in epidoc
    basePathBody = "/TEI/text/body/div"
    basePathHeader = "/TEI/teiHeader/fileDesc/"

    publicationPath = "[@type='bibliography'][@subtype='principalEdition']/listBibl/"
    provenancePath = "[@type='history'][@subtype='locations']/p/"

    # A hash from attribute symbol to either:
    # (1) a String containing XPath for text
    # (2) an array where the first element is (1) and the last is a hash
    #     of attributes to xml attributes
    attributes_xpath_hash = {
      :textDate =>
        [
          basePathHeader + "sourceDesc/msDesc/history/origin/origDate[@type='textDate']",
          {
            :onDate => "when",
            :notAfterDate => "notAfter",
            :notBeforeDate => "notBefore"
          }
        ],
      :titleStmt => basePathHeader + "titleStmt/title",
      :publicationTitle => 
        basePathBody + publicationPath + 
          "bibl[@type='publication'][@subtype='principal']/" + 
          "title",
      :publicationVolume =>
        basePathBody + publicationPath + 
          "bibl[@type='publication'][@subtype='principal']/" + 
          "biblScope[@type='volume']",
      :publicationNumbers => 
        basePathBody + publicationPath +
          "bibl[@type='publication'][@subtype='principal']/" +
          "biblScope[@type='numbers']",
      :tm_nr => 
        basePathHeader + 
          "publicationStmt/idno[@type='TM']",
      :illustrations => 
        basePathBody + "[@type='bibliography'][@subtype='illustrations']/p",
      #not sure what to do about multiples
      #:contentText => "/TEI/teiHeader/profileDesc/textClass/keywords/term(1)",
      :contentText => "/TEI/teiHeader/profileDesc/textClass/keywords/term[position() = 1]",
      :other_publications => 
        basePathBody + "[@type='bibliography'][@subtype='otherPublications']/" + 
          "bibl[@type='publication'][@subtype='other']",
      #tweaked but may need more added to form - may have multiples
      :translations => 
        basePathBody + "[@type='bibliography'][@subtype='translations']/listBibl/bibl[@type='translations']",
      #works same but may need more added to form
      :bl => basePathBody + "[@type='bibliography']/bibl[@type='BL']",
      :notes => basePathBody + "[@type='commentary'][@subtype='general']/p",
      #added this one
      :mentioned_dates_hdr => 
        basePathBody + "[@type='commentary'][@subtype='mentionedDates']/head",
      :mentioned_dates => 
        basePathBody + "[@type='commentary'][@subtype='mentionedDates']/p",
      :material => basePathHeader + "sourceDesc/msDesc/physDesc/objectDesc/supportDesc/support/material",
      :provenance_ancient_findspot => 
        basePathHeader + "sourceDesc/msDesc/history/origin/p/placeName[@type='ancientFindspot']",
      :provenance_nome =>
        basePathHeader + "sourceDesc/msDesc/history/origin/p/geogName[@type='nome']",
      :provenance_ancient_region =>
        basePathHeader + "sourceDesc/msDesc/history/origin/p/geogName[@type='ancientRegion']",
      #guessed at this one
      :provenance_modern_findspot =>
        basePathHeader + "sourceDesc/msDesc/history/origin/p/geogName[@type='modernFindspot']",
      :inventory_number =>
        basePathHeader + "sourceDesc/msDesc/msIdentifier/idno[@type='invNo']", 
      #does not currently exist in data
      :planned_for_future_print_release =>
        basePathHeader + "publicationStmt/idno[@type='futurePrintRelease']"
    }
  end

  def get_or_set_epidoc(get_or_set = :get)
    doc = REXML::Document.new self.content

    self.class.attributes_xpath_hash.each_pair do |self_attribute, value|
      if value.class == String
        xpath = value
        xml_attributes = {}
      elsif value.class == Array
        xpath = value.first
        xml_attributes = value.last
      end
      
      if (get_or_set == :set) && !self[self_attribute].empty? && !xpath.index(/\(\d*\)/)
        doc.bulldozePath xpath # assure xpath exists
      end

      REXML::XPath.each(doc, xpath) do |res|
        xml_attributes.each_pair do |nested_self_attribute, xml_attribute|
          get_or_set_xml_attribute(get_or_set, nested_self_attribute, res, xml_attribute)
        end
        get_or_set_xml_text(get_or_set, self_attribute, res)
      end
   end

    # write back to a string
    modified_xml_content = ''
    doc.write modified_xml_content
    return modified_xml_content
  end

end
