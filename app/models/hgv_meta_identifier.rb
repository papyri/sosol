class HGVMetaIdentifier < HGVIdentifier
  PATH_PREFIX = 'HGV_meta_EpiDoc'

  def self.friendly_name
    return "Meta"
  end
  
  def to_path
    if alternate_name.nil?
      # no alternate name, use SoSOL temporary path
      return self.temporary_path
    else
      path_components = [ PATH_PREFIX ]
      # assume the alternate name is e.g. hgv2302zzr
      trimmed_name = alternate_name.sub(/^hgv/, '') # 2302zzr
      number = trimmed_name.sub(/\D/, '').to_i # 2302

      hgv_dir_number = ((number - 1) / 1000) + 1
      hgv_dir_name = "HGV#{hgv_dir_number}"
      hgv_xml_path = trimmed_name + '.xml'

      path_components << hgv_dir_name << hgv_xml_path

      # e.g. HGV_meta_EpiDoc/HGV3/2302zzr.xml
      return File.join(path_components)
    end
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
    return [:onDate, :notAfterDate, :notBeforeDate, :textDate, :title, :publicationTitle, :publicationVolume, :publicationNumbers,
      :tm_nr, :illustrations, :contentText, :other_publications,
      :translations, :bl, :notes, :mentioned_dates, :material,
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
    basePathBody = "/TEI.2/text/body/div"
    basePathHeader = "/TEI.2/teiHeader/fileDesc/"

    publicationPath = "[@type='bibliography'][@subtype='principalEdition']/listBibl/"
    provenancePath = "[@type='history'][@subtype='locations']/p/"

    # A hash from attribute symbol to either:
    # (1) a String containing XPath for text
    # (2) an array where the first element is (1) and the last is a hash
    #     of attributes to xml attributes
    attributes_xpath_hash = {
      :textDate =>
        [
          basePathBody + "[@type='commentary'][@subtype='textDate']/" + 
            "p/date[@type='textDate']",
          {
            :onDate => "value",
            :notAfterDate => "notAfter",
            :notBeforeDate => "notBefore"
          }
        ],
      :title => basePathHeader + "titleStmt/title/",
      :publicationTitle => 
        basePathBody + publicationPath + 
          "bibl[@type='publication'][@subtype='principal']/" + 
          "title/",
      :publicationVolume =>
        basePathBody + publicationPath + 
          "bibl[@type='publication'][@subtype='principal']/" + 
          "biblScope[@type='volume']/",
      :publicationNumbers => 
        basePathBody + publicationPath +
          "bibl[@type='publication'][@subtype='principal']/" +
          "biblScope[@type='numbers']/",
      :tm_nr => 
        basePathBody + publicationPath + 
          "bibl[@type='Trismegistos']/biblScope[@type='numbers']",
      :illustrations => 
        basePathBody + "[@type='bibliography'][@subtype='illustrations']/p",
      :contentText => basePathBody + "[@type='...']/p/rs[@type='textType']",
      :other_publications => 
        basePathBody + "[@type='bibliography'][@subtype='otherPublications']/" + 
          "bibl[@type='publication'][@subtype='other']/",
      :translations => 
        basePathBody + "[@type='bibliography'][@n='translations']/p",
      :bl => basePathBody + "[@type='bibliography']/bibl[@type='BL']",
      :notes => basePathBody + "[@type='commentary'][@subtype='general']/p",
      :mentioned_dates => 
        basePathBody + "[@type='commentary'][@subtype='general']/p/head",
      :material => basePathBody + "[@type='description']/p/rs[@type='material']",
      :provenance_ancient_findspot => 
        basePathBody + provenancePath + "placeName[@type='ancientFindspot']",
      :provenance_nome =>
        basePathBody + provenancePath + "geogName[@type='nome']",
      :provenance_ancient_region =>
        basePathBody + provenancePath + "geogName[@type='ancientRegion']",
      :provenance_modern_findspot =>
        basePathBody + provenancePath + "placeName[@type='modernFindspot']",
      :inventory_number =>
        basePathHeader + "sourceDesc/msDesc/msIdentifier/idno[@type='invno']", 
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
      
      if (get_or_set == :set) && !self[self_attribute].empty?
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