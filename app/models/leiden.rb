class Leiden < DDBIdentifier  
 
    #created as sub-class of DDBIdentifier because it already has the acts_as_leiden_plus
 
  def self.xml_leiden_plus(content)
    
    if content.include?("<ab><div") || content.include?("<ab><ab")
      #if user xml content included <div> or <ab> tag, remove the <ab> tag added in controller 
      #also means no need to slice after converted
      content.slice!(/^<ab>/)
      content.slice!(/<\/ab>$/)
      #add <wrapab> tag
      abs = DDBIdentifier.preprocess_abs(content)
      #call to convert
      transformed = DDBIdentifier.xml2nonxml(abs)
    else
      #add <wrapab> tag
      abs = DDBIdentifier.preprocess_abs(content)
      #call to convert
      transformed = DDBIdentifier.xml2nonxml(abs)
      
      #remove <= and => that represents <ab> tag added in controller
      transformed.slice!(/^<=/)
      transformed.slice!(/=>$/)
    end
    return transformed
  end
  
  def self.leiden_plus_xml(content)
    
    if content.include?("<=") #check if user input contains Leiden+ grammar for <ab> tag
      #call to convert
      tempTrans = DDBIdentifier.nonxml2xml(content)
      
      # remove namespace assignment or REXML barfs
      tempTrans.sub!(/ xmlns:xml="http:\/\/www.w3.org\/XML\/1998\/namespace"/,'')
        
      # pull out XML inside the <wrapab> tag
      transformed = REXML::XPath.match(REXML::Document.new(tempTrans), '/wrapab/[not(self::wrapab)]')
    else
      # add Leiden+ grammar for <ab> tag so will meet minimun xSugar grammar requirement
      abs = "<=" + content + "=>"
    
      #call to convert
      tempTrans = DDBIdentifier.nonxml2xml(abs)
      
      # remove namespace assignment or REXML barfs
      tempTrans.sub!(/ xmlns:xml="http:\/\/www.w3.org\/XML\/1998\/namespace"/,'')
      
      # pull out XML inside the <ab> tag
      transformed = REXML::XPath.match(REXML::Document.new(tempTrans), '/wrapab/ab/[not(self::ab)]')
    end
    return transformed
  end
  
end
