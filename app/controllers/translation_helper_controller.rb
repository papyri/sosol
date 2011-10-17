class TranslationHelperController < ApplicationController
  
  layout false
  
	def terms
		#get the terms 
		gloss = HGVTransGlossary.new
		
		@glossary = gloss.to_chooser
		
	end
	
	def new_lang
	end
	
	def linebreak
	end
  
  def gaplost
  end
  
  def gapelliplang
  end
  
  def gapellipNT
  end
  
  def gapilleg
  end
  
  def division
  end
  
  def tryit
  end

end
