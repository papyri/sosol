require "rexml/document"


class Meta < ActiveRecord::Base
  belongs_to :article
  
  def get_content()
  	#TODO create epidoc?
  	#hack return strings for now  
  	separator = "/n"
  	retval = " notBeforeDate: "	  
  	retval += self.notBeforeDate unless self.notBeforeDate == nil
  	retval += separator
  	
  	retval += " notAfterDate: "
    retval += self.notAfterDate unless self.notAfterDate  == nil
  	retval += separator
  	
    retval += " onDate: "
    retval += self.onDate unless self.onDate  == nil
  	retval += separator
  	
    retval += " publication: "
    retval += self.publication unless self.publication  == nil
  	retval += separator
  	
    retval += " title: "
    retval += self.title unless self.title  == nil
  	retval += separator
  	
    retval += " notes: "    
    retval += self.notes unless self.notes  == nil
  	retval += separator
  	
    retval += " material: "
    retval += self.material unless self.material  == nil
  	retval += separator
  	
    retval += " BL: "
    retval += self.bl unless self.bl  == nil
  	retval += separator
  	
    retval += " TM: "
    retval += self.tm_nr unless self.tm_nr  == nil
  	retval += separator
  	
    retval += " content: "
    retval += self.content unless self.content  == nil
  	retval += separator
  	
    retval += " provenence-ancientFindspot: "
    retval += self.provenance_ancient_findspot unless self.provenance_ancient_findspot  == nil
  	retval += separator
  	
    retval += " provenence-nome: "
    retval += self.provenance_nome unless self.provenance_nome  == nil
  	retval += separator
  	
    retval += " provenence-ancientRegion"    
    retval += self.provenance_ancient_region unless self.provenance_ancient_region  == nil
  	retval += separator
  	
    retval += " translations: "
    retval += self.translations unless self.translations  == nil
  	retval += separator
  	
    retval += " other publications: "
    retval += self.other_publications unless self.other_publications  == nil
  	retval += separator
  	
    retval += " illustration: "
    retval += self.illustration unless self.illustration  == nil
  	retval += separator
  	
#    retval += " "
#    retval += self. unless self.  == nil
#    retval += " "
#    retval += self. unless self.  == nil
#    retval += " "
#    retval += self. unless self.  == nil
#    retval += " "
#    retval += self. unless self.  == nil
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
  
	file = File.new( filename )
	#file = File.new( "/home/charles/HGV_meta_EpiDoc_HGV1_1.xml" )
	doc = REXML::Document.new file
  
    #set base to meta data in epidoc
    basePath = "TEI.2/text/body/div"    
    
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
      self.tm_nr = res.text    
    end


#-----------------unused--------------------
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
    
#===============end unused==================        
    
    #illustration - photo
    illustrationPath = "[@type='bibliography'][@subtype='illustrations']/p"        
    metaPath = basePath + illustrationPath;
    REXML::XPath.each(doc, metaPath) do |res|
      self.illustrations = res.text    
    end  
        
    #Content
    #TODO replace ...? or is that actually a tag?
    contentPath = "[@type='...']/p/rs[@type='textType']"    
    metaPath = basePath + contentPath;
    REXML::XPath.each(doc, metaPath) do |res|
      self.content = res.text    
    end      
        
    #Other Publication
    otherPublicationPath = "[@type='bibliography'][@subtype='otherPublications']/p/bibl"    
    metaPath = basePath + otherPublicationPath;
    REXML::XPath.each(doc, metaPath) do |res|
      self.other_publications = res.text    #note items are separated by semicolons
    end    
    
    #Translations
    translationsPath = "[@type='bibliography'][@n='translations']/p"    
    metaPath = basePath + translationsPath;
    REXML::XPath.each(doc, metaPath) do |res|
      translations = res.text    
    end    
    
		#BL
    blPath = "[@type='bibliography']/bibl[@type='BL']"    
    metaPath = basePath + blPath;
    REXML::XPath.each(doc, metaPath) do |res|
      self.bl = res.text    
    end
    
    #notes - aka general commentary, will there only be one?
    notePath = "[@type='commentary'][@subtype='general']/p"       
    metaPath = basePath + notePath;
    REXML::XPath.each(doc, metaPath) do |res|
      self.notes = res.text    
    end                
    
    #mentioned dates - aka mentioned dates commentary, will there only be one?
    notePath = "[@type='commentary'][@subtype='general']/p/head"       
    metaPath = basePath + notePath;
    REXML::XPath.each(doc, metaPath) do |res|
      self.mentioned_dates = res.text    
    end            
    
    #material
    materialPath = "[@type='description']/p/rs[@type='material']"
    metaPath = basePath + materialPath
    REXML::XPath.each(doc, metaPath) do |res|
      self.material = res.text    
    end    
 
    #provenance
    provenacePath = "[@type='history'][@subtype='locations']/p/"
    
    provenacePathA = "placeName[@type='ancientFindspot']"   
		metaPath = basePath + provenacePath + provenacePathA
    REXML::XPath.each(doc, metaPath) do |res|
      self.provenance_ancient_findspot = res.text    
    end 
       
    provenacePathB = "geogName[@type='nome']"
		metaPath = basePath + provenacePath + provenacePathB
    REXML::XPath.each(doc, metaPath) do |res|
      self.provenance_nome = res.text    
    end 
          
    provenacePathC = "geogName[@type='ancientRegion']" 
		metaPath = basePath + provenacePath + provenacePathC
    REXML::XPath.each(doc, metaPath) do |res|
      self.provenance_ancient_region = res.text    
    end 
    
      #Mentioned dates ?? no epidoc tag?
       
  end
  
end
