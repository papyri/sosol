class TranslationLeiden < HGVTransIdentifier  
 
	#created as sub-class of HGVTransIdentifier because it already has the acts_as_translation
 
	def self.xml_to_translation_leiden(content)
 
		
		#def self.xml_leiden_plus(content)
 # transformed = "pig"
    #add <wrapab> tag
    #abs = DDBIdentifier.preprocess_abs(content)
    #call to convert
    
    transformed = HGVTransIdentifier.xml2nonxml(content)
  
    #if transformed = nil we crash here, where to fix?
    
    #remove <= and => that represents <wrapab>
    transformed.slice!(/^<T=.en <=/)
    transformed.slice!(/=>=T>$/)
		

    return transformed
  end
  
  def self.translation_leiden_to_xml(content)
  #def self.leiden_plus_xml(content)
    
 
  	#leiden to xml
  	transformed = HGVTransIdentifier.leiden_translation_to_xml(content)
  	
  	
  	# add Leiden+ grammar for <ab> tag so will meet minimun xSugar grammar requirement
 #   abs = "<=" + content + "=>"
    #call to convert
 #   tempTrans = DDBIdentifier.nonxml2xml(abs)
    # pull out XML inside the <ab> tag
  #  transformed = REXML::XPath.match(REXML::Document.new(tempTrans), '/wrapab/ab/[not(self::ab)]')
    
    return transformed
  end
  
end
