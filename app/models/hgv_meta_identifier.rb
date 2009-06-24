class HGVMetaIdentifier < Identifier
  HGV_META_PATH_PREFIX = 'HGV_meta_EpiDoc'
  
  IDENTIFIER_NAMESPACE = 'hgv'
  TEMPORARY_COLLECTION = 'SoSOL'
  
  ROMAN_MAP = { 1 => "I",
                4 => "IV",
                5 => "V",
                9 => "IX",
                10 => "X",
                40 => "XL",
                50 => "L",
                90 => "XC",
                100 => "C",
                400 => "CD",
                500 => "D",
                900 => "CM",
                1000 => "M" }

  def to_path
    path_components = [ HGV_META_PATH_PREFIX ]
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
  
  def to_roman(arabic)
    # shamelessly stolen from http://rubyquiz.com/quiz22.html
    ROMAN_MAP.keys.sort { |a, b| b <=> a }.inject("") do |roman, div|
      times, arabic = arabic.divmod(div)
      roman << ROMAN_MAP[div] * times
    end
  end
  
  def titleize
    trimmed_name = name.sub(/^oai:papyri.info:identifiers:hgv:/, '')
    components = trimmed_name.split(':')
    hgv_collection_name = components[0].to_s
    hgv_volume_number = components[1].to_s
    hgv_document_number = components[2].to_s
    
    components[1] = to_roman(components[1].to_i)
    
    # [hgv_collection_name, to_roman(hgv_volume_number.to_i), hgv_document_number].join(' ')
    components.join(' ')
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
  
  def valid_epidoc_attributes
    return [:onDate, :notAfterDate, :notBeforeDate, :title, :publicationTitle,
      :tm_nr, :illustrations, :contentText, :other_publications,
      :translations, :bl, :notes, :mentioned_dates, :material,
      :provenance_ancient_findspot, :provenance_nome,
      :provenance_ancient_region]
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

  def get_or_set_epidoc(get_or_set = :get)
    doc = REXML::Document.new self.content

    # set base to meta data in epidoc
    basePath = "TEI.2/text/body/div"

    # date
    datePath = "[@type='commentary'][@subtype='textDate']"
    metaPath = basePath + datePath + "/p/date[@type='textDate']"
    REXML::XPath.each(doc,metaPath)  do |res|
      get_or_set_xml_attribute(get_or_set, :onDate, res, "value")
      get_or_set_xml_attribute(get_or_set, :notAfterDate, res, "notAfter")
      get_or_set_xml_attribute(get_or_set, :notBeforeDate, res, "notBefore")
    end


    # publication
    publicationPath = "[@type='bibliography'][@subtype='principalEdition']/listBibl/"

    # title
    # incorrect title titlePath = "bibl[@type='publication'][@subtype='principal']/title/"
    titlePath = "TEI.2/teiHeader/fileDesc/titleStmt/title/"

    # metaPath = basePath + publicationPath + titlePath
    metaPath = titlePath
    REXML::XPath.each(doc, metaPath) do |res|
      get_or_set_xml_text(get_or_set, :title, res)
    end


    # publication
    publicationPath = "[@type='bibliography'][@subtype='principalEdition']/listBibl/"

    # title
    titlePath = "bibl[@type='publication'][@subtype='principal']/title/"

    metaPath = basePath + publicationPath + titlePath
    REXML::XPath.each(doc, metaPath) do |res|
      get_or_set_xml_text(get_or_set, :publicationTitle, res)
    end


    # TM number
    trismegistosPath = "bible[@type='Trismegistos']/biblScope[@type='numbers']"
    metaPath = basePath + publicationPath + trismegistosPath;
    REXML::XPath.each(doc, metaPath) do |res|
      get_or_set_xml_text(get_or_set, :tm_nr, res)
    end


    # -----------------unused--------------------
    # DDbDp number
    dukeSeries = "bibl/[@type='DDbDP']/series"
    dukeNumber = "bibl/[@type='DDbDP']/biblScope[@type='numbers']"

  metaPath = basePath + publicationPath + dukeSeries;
    REXML::XPath.each(doc, metaPath) do |res|
      # TODO
      replaceMe = res.text
    end

  metaPath = basePath + publicationPath + dukeNumber;
    REXML::XPath.each(doc, metaPath) do |res|
      # TODO
      replaceMe = res.text
    end

    # Perseus links
    perseusPath = "p/xref[@type='Perseus']"

  metaPath = basePath + publicationPath + perseusPath;
    REXML::XPath.each(doc, metaPath) do |res|
      # TODO
      replaceMe = res.attributes["href"]
      replaceMe = res.text
    end

    # ===============end unused==================

    # illustration - photo
    illustrationPath = "[@type='bibliography'][@subtype='illustrations']/p"
    metaPath = basePath + illustrationPath;
    REXML::XPath.each(doc, metaPath) do |res|
      get_or_set_xml_text(get_or_set, :illustrations, res)
    end

    # Content
    # TODO replace ...? or is that actually a tag?
    contentPath = "[@type='...']/p/rs[@type='textType']"
    metaPath = basePath + contentPath;
    REXML::XPath.each(doc, metaPath) do |res|
      get_or_set_xml_text(get_or_set, :contentText, res)
    end

    # Other Publication
    otherPublicationPath = "[@type='bibliography'][@subtype='otherPublications']/p/bibl"
    metaPath = basePath + otherPublicationPath;
    REXML::XPath.each(doc, metaPath) do |res|
      get_or_set_xml_text(get_or_set, :other_publications, res)    # note items are separated by semicolons
    end

    # Translations
    translationsPath = "[@type='bibliography'][@n='translations']/p"
    metaPath = basePath + translationsPath;
    REXML::XPath.each(doc, metaPath) do |res|
      get_or_set_xml_text(get_or_set, :translations, res)
    end

    # BL
    blPath = "[@type='bibliography']/bibl[@type='BL']"
    metaPath = basePath + blPath;
    REXML::XPath.each(doc, metaPath) do |res|
      get_or_set_xml_text(get_or_set, :bl, res)
    end

    # notes - aka general commentary, will there only be one?
    notePath = "[@type='commentary'][@subtype='general']/p"
    metaPath = basePath + notePath;
    REXML::XPath.each(doc, metaPath) do |res|
      get_or_set_xml_text(get_or_set, :notes, res)
    end

    # mentioned dates - aka mentioned dates commentary, will there only be one?
    notePath = "[@type='commentary'][@subtype='general']/p/head"
    metaPath = basePath + notePath;
    REXML::XPath.each(doc, metaPath) do |res|
      get_or_set_xml_text(get_or_set, :mentioned_dates, res)
    end

    # material
    materialPath = "[@type='description']/p/rs[@type='material']"
    metaPath = basePath + materialPath
    REXML::XPath.each(doc, metaPath) do |res|
      get_or_set_xml_text(get_or_set, :material, res)
    end

    # provenance
    provenacePath = "[@type='history'][@subtype='locations']/p/"

    provenacePathA = "placeName[@type='ancientFindspot']"
    metaPath = basePath + provenacePath + provenacePathA
    REXML::XPath.each(doc, metaPath) do |res|
      get_or_set_xml_text(get_or_set, :provenance_ancient_findspot, res)
    end

    provenacePathB = "geogName[@type='nome']"
    metaPath = basePath + provenacePath + provenacePathB
    REXML::XPath.each(doc, metaPath) do |res|
      get_or_set_xml_text(get_or_set, :provenance_nome, res)
    end

    provenacePathC = "geogName[@type='ancientRegion']"
    metaPath = basePath + provenacePath + provenacePathC
    REXML::XPath.each(doc, metaPath) do |res|
      get_or_set_xml_text(get_or_set, :provenance_ancient_region, res)
    end


    # Mentioned dates ?? no epidoc tag?
    
    # write back to a string
    modified_xml_content = ''
    doc.write(modified_xml_content)
    return modified_xml_content
  end
end