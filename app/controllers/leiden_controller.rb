class LeidenController < ApplicationController
  
  def xmlAjax
    
    xml2conv = (params[:xml])
    
    leidenback = Leiden.xml_leiden_plus(xml2conv)
    
    render :text => "#{leidenback}"
  end

end
