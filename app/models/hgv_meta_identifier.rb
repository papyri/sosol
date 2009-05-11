class HGVMetaIdentifier < Identifier
  HGV_META_PATH_PREFIX = 'HGV_meta_EpiDoc'

  def to_path
    path_components = [ HGV_META_PATH_PREFIX ]
    # for now, assume the name is e.g. hgv2302zzr
    trimmed_name = name.sub(/^hgv/, '') # 2302zzr
    number = trimmed_name.sub(/\D/, '').to_i # 2302

    hgv_dir_number = ((number - 1) / 1000) + 1
    hgv_dir_name = "HGV#{hgv_dir_number}"
    hgv_xml_path = trimmed_name + '.xml'

    path_components << hgv_dir_name << hgv_xml_path

    # e.g. HGV_meta_EpiDoc/HGV3/2302zzr.xml
    return path_components.join('/')
  end
  
  def epidoc_attributes
    return [:onDate, :notAfterDate, :notBeforeDate, :title, :publicationTitle,
      :tm_nr, :illustrations, :contentText, :other_publications,
      :translations, :bl, :notes, :mentioned_dates, :material,
      :provenance_ancient_findspot, :provenance_nome,
      :provenance_ancient_region]
  end

  def load_epidoc_from_file
    doc = REXML::Document.new self.content

    # set base to meta data in epidoc
    basePath = "TEI.2/text/body/div"

    # date
    datePath = "[@type='commentary'][@subtype='textDate']"
    metaPath = basePath + datePath + "/p/date[@type='textDate']"
    REXML::XPath.each(doc,metaPath)  do |res|
      self[:onDate] = res.attributes["value"]
      self[:notAfterDate] = res.attributes["notAfter"]
      self[:notBeforeDate] = res.attributes["notBefore"]
    end


    # publication
    publicationPath = "[@type='bibliography'][@subtype='principalEdition']/listBibl/"

    # title
    # incorrect title titlePath = "bibl[@type='publication'][@subtype='principal']/title/"
    titlePath = "TEI.2/teiHeader/fileDesc/titleStmt/title/"

    # metaPath = basePath + publicationPath + titlePath
    metaPath = titlePath
    REXML::XPath.each(doc, metaPath) do |res|
      self[:title] = res.text
    end


    # publication
    publicationPath = "[@type='bibliography'][@subtype='principalEdition']/listBibl/"

    # title
    titlePath = "bibl[@type='publication'][@subtype='principal']/title/"

    metaPath = basePath + publicationPath + titlePath
    REXML::XPath.each(doc, metaPath) do |res|
      self[:publicationTitle] = res.text
    end


    # TM number
    trismegistosPath = "bible[@type='Trismegistos']/biblScope[@type='numbers']"
    metaPath = basePath + publicationPath + trismegistosPath;
    REXML::XPath.each(doc, metaPath) do |res|
      self[:tm_nr] = res.text
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
      self[:illustrations] = res.text
    end

    # Content
    # TODO replace ...? or is that actually a tag?
    contentPath = "[@type='...']/p/rs[@type='textType']"
    metaPath = basePath + contentPath;
    REXML::XPath.each(doc, metaPath) do |res|
      self[:contentText] = res.text
    end

    # Other Publication
    otherPublicationPath = "[@type='bibliography'][@subtype='otherPublications']/p/bibl"
    metaPath = basePath + otherPublicationPath;
    REXML::XPath.each(doc, metaPath) do |res|
      self[:other_publications] = res.text    # note items are separated by semicolons
    end

    # Translations
    translationsPath = "[@type='bibliography'][@n='translations']/p"
    metaPath = basePath + translationsPath;
    REXML::XPath.each(doc, metaPath) do |res|
      self[:translations] = res.text
    end

    # BL
    blPath = "[@type='bibliography']/bibl[@type='BL']"
    metaPath = basePath + blPath;
    REXML::XPath.each(doc, metaPath) do |res|
      self[:bl] = res.text
    end

    # notes - aka general commentary, will there only be one?
    notePath = "[@type='commentary'][@subtype='general']/p"
    metaPath = basePath + notePath;
    REXML::XPath.each(doc, metaPath) do |res|
      self[:notes] = res.text
    end

    # mentioned dates - aka mentioned dates commentary, will there only be one?
    notePath = "[@type='commentary'][@subtype='general']/p/head"
    metaPath = basePath + notePath;
    REXML::XPath.each(doc, metaPath) do |res|
      self[:mentioned_dates] = res.text
    end

    # material
    materialPath = "[@type='description']/p/rs[@type='material']"
    metaPath = basePath + materialPath
    REXML::XPath.each(doc, metaPath) do |res|
      self[:material] = res.text
    end

    # provenance
    provenacePath = "[@type='history'][@subtype='locations']/p/"

    provenacePathA = "placeName[@type='ancientFindspot']"
    metaPath = basePath + provenacePath + provenacePathA
    REXML::XPath.each(doc, metaPath) do |res|
      self[:provenance_ancient_findspot] = res.text
    end

    provenacePathB = "geogName[@type='nome']"
    metaPath = basePath + provenacePath + provenacePathB
    REXML::XPath.each(doc, metaPath) do |res|
      self[:provenance_nome] = res.text
    end

    provenacePathC = "geogName[@type='ancientRegion']"
    metaPath = basePath + provenacePath + provenacePathC
    REXML::XPath.each(doc, metaPath) do |res|
      self[:provenance_ancient_region] = res.text
    end

    # Set nil attrs to empty strings
    epidoc_attributes.each do |this_attr|
        if self[this_attr].nil?
          self[this_attr] = ''
        end
    end

    # Mentioned dates ?? no epidoc tag?
  end
end