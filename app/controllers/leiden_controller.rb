class LeidenController < ApplicationController
  
  def xmlAjax
    
    xml2conv = (params[:xml])
    
    leidenback = Leiden.xml_leiden_plus(xml2conv)
    
    render :text => "#{leidenback}"
  end
  
  def leiden2xml
    
    leiden2conv = (params[:leiden])
    
    xmlback = Leiden.leiden_plus_xml(leiden2conv)
    
    render :text => "#{xmlback}"
  end

end
