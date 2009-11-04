class Leiden < DDBIdentifier  
 
    #created as sub-class of DDBIdentifier because it already has the acts_as_leiden_plus
 
  def self.xml_leiden_plus(content)
    #add <wrapab> tag
    abs = DDBIdentifier.preprocess_abs(content)
    begin
      #call to convert
      transformed = DDBIdentifier.xml2nonxml(abs)
      
      #remove <= and => that represents <wrapab>
      transformed.slice!(/^<=/)
      transformed.slice!(/=>$/)

    rescue Exception => e
      if e.message.to_s =~ /^dk\.brics\.grammar\.parser\.ParseException: parse error at character (\d+)/
        return e.message.to_s + "\n" + 
          DDBIdentifier.parse_exception_pretty_print(abs, $1.to_i)
      end
    end
    return transformed
  end
  
  def self.leiden_plus_xml(content)
    # add Leiden+ grammar for <ab> tag so will meet minimun xSugar grammar requirement
    abs = "<=" + content + "=>"
    begin
      #call to convert
      tempTrans = DDBIdentifier.nonxml2xml(abs)
      # pull out only the XML tags inside the <ab> tag
      transformed = REXML::XPath.match(REXML::Document.new(tempTrans), '/wrapab/ab/*')
    
    rescue Exception => e
      if e.message.to_s =~ /^dk\.brics\.grammar\.parser\.ParseException: parse error at character (\d+)/
        return e.message.to_s + "\n" + 
          DDBIdentifier.parse_exception_pretty_print(abs, $1.to_i)
      end
    end
    return transformed
  end
  
end
