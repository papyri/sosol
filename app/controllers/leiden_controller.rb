#No associated views - just call the methods to do DDB Text Leiden+ and XML conversions
class LeidenController < ApplicationController
  
  # Transform DDB Text XML to Leiden+ - used in the DDB Text Helper menu - used in javascript ajax call
  # - *Params*  :
  #   - +xml+ -> DDB Text XML to transform to Leiden+
  # - *Returns* :
  #   - Leiden+
  # - *Rescue*  :
  #   - RXSugar::XMLParseError - formats and returns error message if transform fails
  def xml2leiden
    
    xml2conv = (params[:xml])
    begin
      leidenback = Leiden.xml_leiden_plus(xml2conv)
      render :plain => "#{leidenback}"
    rescue RXSugar::XMLParseError => parse_error
      #insert **ERROR** into content to help user find it - subtract 1 for offset from 0
      #added 68 to above because of "xml:" in 'div edition being replaced twice during the
      #normalize xml process in xsugar processing in rxsugar.xml_to_non_xml with {http://www.w3.org/XML/1998/namespace}
      # this is (38 chars - 4) * 2 = 68. removed 68 in error message also not offset.
      parse_error.content.insert((parse_error.column-69), "**ERROR**")
      render :plain => "Error at column #{parse_error.column-68} #{parse_error.content}"
    end
  end
  
  # Transform DDB Text Leiden+ to XML - used in the DDB Text Helper menu - used in javascript ajax call
  # - *Params*  :
  #   - +leiden+ -> DDB Text Leiden+ to transform to XML
  # - *Returns* :
  #   - XML
  # - *Rescue*  :
  #   - RXSugar::NonXMLParseError - formats and returns error message if transform fails
  def leiden2xml
    
    leiden2conv = (params[:leiden])
    begin
      xmlback = Leiden.leiden_plus_xml(leiden2conv)
      render :plain => "#{xmlback}"
    rescue RXSugar::NonXMLParseError => parse_error
      #insert **ERROR** into content to help user find it - subtract 1 for offset from 0
      parse_error.content.insert((parse_error.column-1), "**ERROR**")
      render :plain => "Error at column #{parse_error.column} #{parse_error.content}"
    end
    
    
  end

end
