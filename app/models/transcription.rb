class Transcription < ActiveRecord::Base
  belongs_to :article
  
  
  def get_content()
  	"not yet implemented"
  end
  
  
end
