require "rexml/document"


class Meta < ActiveRecord::Base
  belongs_to :article
  
  def get_content()
  	#TODO create epidoc?
  	#hack return strings for now  
  	
  	retval = " "	  
  	retval += self.notBeforeDate unless self.notBeforeDate == nil
  	retval += " "
    retval += self.notAfterDate unless self.notAfterDate  == nil
    retval += " "
    retval += self.onDate unless self.onDate  == nil
    retval += " "
    retval += self.publication unless self.publication  == nil
    retval += " "
    retval += self.language unless self.language  == nil
    retval += " "
    retval += self.subject unless self.subject  == nil
    retval += " "
    retval += self.title unless self.title  == nil
    retval += " "
    retval += self.provenance unless self.provenance  == nil
    retval += " "
    retval += self.notes unless self.notes  == nil
    retval += " "
  end
  
  
  def load_epidoc_from_tm(tm_number)
  	filename = get_filename_from_tm(tm_number)
  	load_epidoc_from_file(filename)
  end
  
  def get_filename_from_tm(tm_number)

  	hgvDirNumber = tm_number.to_i / 1000
  	hgvDirNumber = hgvDirNumber.to_i + 1
  	hgvDir = "HGV" + hgvDirNumber.to_s
  	
  	filename = META_DIR + hgvDir + '/' + tm_number.to_s + ".xml"
  end
  
  
  def load_epidoc_from_file(filename)
    
	file = File.new( filename )#"/home/charles/HGV_meta_EpiDoc_HGV1_1.xml" )
	doc = REXML::Document.new file
  
    #set base to meta data in epidoc
    basePath = "TEI.2/text/body/div"
    
    #notes
    notePath = "[@type='commentary'][@subtype='general']/p"
        
    metaPath = basePath + notePath;
    REXML::XPath.each(doc, metaPath) do |res|
      #TODO
      self.notes = res.text    
    end
    
    
    #date
    datePath = "[@type='commentary'][@subtype='textDate']"
		metaPath = basePath + datePath + "/p/date[@type='textDate']"
		REXML::XPath.each(doc,metaPath)  do |res|
      self.onDate = res.attributes["value"]
      self.notAfterDate = res.attributes["notAfter"]
      self.notBeforeDate = res.attributes["notBefore"]
    end\
    
    
    #publication
    publicationPath = "[@type='bibliography'][@subtype='principalEdition']/listBibl/"
    
    #title
    #incorrect title titlePath = "bibl[@type='publication'][@subtype='principal']/title/"    
    titlePath = "TEI.2/teiHeader/fileDesc/titleStmt/title/"
    
    #metaPath = basePath + publicationPath + titlePath
    metaPath = titlePath
    REXML::XPath.each(doc, metaPath) do |res|
      self.title = res.text    
    end
    
    
    #publication
    publicationPath = "[@type='bibliography'][@subtype='principalEdition']/listBibl/"    

    #title
    titlePath = "bibl[@type='publication'][@subtype='principal']/title/"        
    
    metaPath = basePath + publicationPath + titlePath
    REXML::XPath.each(doc, metaPath) do |res|
      self.publication = res.text    
    end
    
    
    #TM number
    trismegistosPath = "bible[@type='Trismegistos']/biblScope[@type='numbers']"
		metaPath = basePath + publicationPath + trismegistosPath;
    REXML::XPath.each(doc, metaPath) do |res|
      #TODO
      replaceMe = res.text    
    end

    #DDbDp number
    dukeSeries = "bibl/[@type='DDbDP']/series"
    dukeNumber = "bibl/[@type='DDbDP']/biblScope[@type='numbers']"

	metaPath = basePath + publicationPath + dukeSeries;
    REXML::XPath.each(doc, metaPath) do |res|
      #TODO
      replaceMe = res.text    
    end    
    
	metaPath = basePath + publicationPath + dukeNumber;
    REXML::XPath.each(doc, metaPath) do |res|
      #TODO
      replaceMe = res.text    
    end
    
    #Perseus links
    perseusPath = "p/xref[@type='Perseus']"
    
	metaPath = basePath + publicationPath + perseusPath;
    REXML::XPath.each(doc, metaPath) do |res|
      #TODO
      replaceMe = res.attributes["href"]
      replaceMe = res.text    
    end
    
    
    #location
    locationPath = "[@type='history'][@subtype='locations']/p/placeName[@type='ancientFindspot']"    
    metaPath = basePath + locationPath;
    REXML::XPath.each(doc, metaPath) do |res|
      self.provenance = res.text    
    end
    
    #illustration
    illustrationPath = "[@type='bibliography'][@subtype='illustrations']/p"        
    metaPath = basePath + illustrationPath;
    REXML::XPath.each(doc, metaPath) do |res|
      #TODO
      replaceMe = res.text    
    end    
       
  end
  
end
