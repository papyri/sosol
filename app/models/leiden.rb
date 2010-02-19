class Leiden < DDBIdentifier  
 
    #created as sub-class of DDBIdentifier because it already has the acts_as_leiden_plus
 
  def self.xml_leiden_plus(content)
    #add <wrapab> tag
    abs = DDBIdentifier.preprocess_abs(content)
    #call to convert
    transformed = DDBIdentifier.xml2nonxml(abs)
    
    #remove <= and => that represents <wrapab>
    transformed.slice!(/^<=/)
    transformed.slice!(/=>$/)

    return transformed
  end
  
  def self.leiden_plus_xml(content)
    # add Leiden+ grammar for <ab> tag so will meet minimun xSugar grammar requirement
    abs = "<=" + content + "=>"
    #call to convert
    tempTrans = DDBIdentifier.nonxml2xml(abs)
    # pull out XML inside the <ab> tag
    transformed = REXML::XPath.match(REXML::Document.new(tempTrans), '/wrapab/ab/[not(self::ab)]')
    
    return transformed
  end
  
end
