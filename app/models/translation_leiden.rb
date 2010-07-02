class TranslationLeiden < HGVTransIdentifier  
 
	#created as sub-class of HGVTransIdentifier because it already has the acts_as_translation
 
	def self.xml_to_translation_leiden(content)
 
		#wrap so that the sugar grammer can transform
		wrapped_content = "<body xmlns:xml=\"http://www.w3.org/XML/1998/namespace\"><div xml:lang=\"en\" type=\"translation\" xml:space=\"preserve\"><p>" + content + "</p></div></body>";
    
		transformed = HGVTransIdentifier.xml2nonxml(wrapped_content)
 
    
    #remove <= and => that represents the wrapping
    if (transformed)
    	transformed.slice!(/^<T=.en <=/)
    	transformed.slice!(/=>=T>$/)
    end
  
    return transformed
  end
  
  def self.translation_leiden_to_xml(content)
  #def self.leiden_plus_xml(content)
    
  	#wrap to minimum needed for sugar grammer
    wrapped_content = '<T=.en <=' + content + '=>=T>'
  
  	#leiden to xml
  	wrapped_transformed = HGVTransIdentifier.nonxml2xml(wrapped_content)
  	
  	transformed = REXML::XPath.match(REXML::Document.new(wrapped_transformed), '/body/div/p/[not(self::p)]')
  #	transformed = wrapped_transformed
  	
 #   abs = "<=" + content + "=>"
    #call to convert
 #   tempTrans = DDBIdentifier.nonxml2xml(abs)
    # pull out XML inside the <ab> tag
  #  transformed = REXML::XPath.match(REXML::Document.new(tempTrans), '/wrapab/ab/[not(self::ab)]')
    
    return transformed
  end
  
end
