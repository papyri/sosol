class TranslationHelperController < ApplicationController
  
  layout false
  
  # Helper Terms
	def terms
		#get the terms 
		gloss = HGVTransGlossary.new
		
		@glossary = gloss.to_chooser
		
	end
	
	def new_lang
	end
	
  # Helper Linebreak
	def linebreak
	end
  
  # Helper Division Other  
  def division
  end
  
  # Helper Tryit
  def tryit
  end

end
