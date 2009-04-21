class Transcription < ActiveRecord::Base
  belongs_to :article
  
  
  def get_content()
  	self.content
  end
  
  
end
