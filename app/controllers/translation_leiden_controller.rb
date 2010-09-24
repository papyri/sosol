class TranslationLeidenController < ApplicationController
  

	#used by ajax
  def xml_to_translation_leiden
    
    xml2conv = (params[:xml])
    begin
      #leidenback = TranslationLeiden.xml_leiden_plus(xml2conv)
      leidenback = TranslationLeiden.xml_to_translation_leiden(xml2conv)
      
      render :text => "#{leidenback}"
    rescue RXSugar::XMLParseError => parse_error
      #insert **ERROR** into content to help user find it - subtract 1 for offset from 0
      parse_error.content.insert((parse_error.column-1), "**ERROR**")
      render :text => xml2conv + "Error at column #{parse_error.column} #{parse_error.content}"
    end
  end
  
  
  
  #used by ajax
  def get_language_translation_leiden
 	
    lang = (params[:lang])
    begin
      leidenback = TranslationLeiden.get_language_translation_leiden(lang)
      render :text => "#{leidenback}"
    rescue RXSugar::XMLParseError => parse_error
      #insert **ERROR** into content to help user find it - subtract 1 for offset from 0
      parse_error.content.insert((parse_error.column-1), "**ERROR**")
      render :text => xml2conv + "Error at column #{parse_error.column} #{parse_error.content}"
    end
  end
  
  #used by ajax
  def translation_leiden_to_xml
    
    leiden2conv = (params[:leiden])
    begin
      #xmlback = TranslationLeiden.leiden_plus_xml(leiden2conv)
      xmlback = TranslationLeiden.translation_leiden_to_xml(leiden2conv)
      
      
      render :text => "#{xmlback}"
    rescue RXSugar::NonXMLParseError => parse_error
      #insert **ERROR** into content to help user find it - subtract 1 for offset from 0
      parse_error.content.insert((parse_error.column-1), "**ERROR**")
      render :text => "Error at column #{parse_error.column} #{parse_error.content}"
    end
    
    
  end

end
