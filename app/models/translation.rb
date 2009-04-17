require "rexml/document"
class XmlCreationError < StandardError

end


class Translation < ActiveRecord::Base
  belongs_to :article
  has_many :translation_contents
  

  
  def approve()
    #the vote has approved the article
    self.article.status = "approved"
    self.article.save
    #choose the finalizer
    #for now pick the last person to vote
    self.article.board.finalizer_user_id = self.article.votes[ self.article.votes.length - 1 ].user_id
    self.article.board.save #need to check on automatic saving of linked models
  	#TODO send them an email
  end
  

 def load_epidoc_from_tm(tm_number)
  	filename = get_filename_from_tm(tm_number)
  	load_epidoc_from_file(filename)
  end
  
  def get_filename_from_tm(tm_number)
		filename = TRANSLATION_DIR + tm_number.to_s + ".xml"   	
  end
  
  def load_epidoc_from_file(filename)   
    file =  File.open(filename, "r")
    self.epidoc = file.read
  	PutEpidocToTranslationContents(true)
  end
  
  #puts the translations present in the epidoc to the translation_contents
  #if delete_extra is true, then any translation_contents that are not in the epidoc will be deleted
  #if translations cannot be gotten from epidoc, false is returned and translation is unchanged
  def PutEpidocToTranslationContents(delete_extra = false)
 
		#todo, add more error checking, ie on tc.save

		#first check that we can get translations from the epidoc
		success, epidoc_tcs = GetTranslationsFromEpidoc()
		if  !success
			return false
		end
    
    epidocLangs = GetLanguagesInEpidoc()    
    #see if we have any extra languages in the translation_contents
    if delete_extra == true
		self.translation_contents.each do |tc|
		  extra_lang = true
		  epidocLangs.each do |el|
			if el == tc.language
			  extra_lang = false
			end
		  end
		  
		  if extra_lang == true
			tc.delete      
		  end
		end
    end

#    success, epidoc_tcs = GetTranslationsFromEpidoc()
        
    epidoc_tcs.each do |etc|
        #see if it already exists    
        exist = false
	    self.translation_contents.each do |tc|
    	  if etc.language == tc.language
    	    if exist == true && delete_extra == true
    	      #we have found a duplicate so delete it
    	      tc.delete
    	    else
    	    	tc.content = etc.content
    	    	tc.save
    	    	exist = true
    	    end
    	  end
    	end
    
    	if exist == false
    	  #need to create new tc
    	  new_tc = TranslationContent.new()
    	  new_tc.language = etc.language
    	  new_tc.content = etc.content
    	  self.translation_contents << new_tc
    	end
    end    
    
    return true
  end
  
  
  
  def GetTranslationsFromTranslationContents()
    tcs = Array.new()    
    self.translation_contents.each do |tc|    
    	tcs << tc    	  
    end
 
  end
  
  #puts the translation_contents model data into the translation epidoc
  def PutTranslationContentsToEpidoc()
    self.translation_contents.each do |tc|
      PutTranslationToEpidoc(tc)
    end
  
  end
  
  #pull out translation sections from epidoc
  #return an array of translation_contents
  def GetTranslationsFromEpidoc()
  	success = true
 
 
 		begin #exception handling
			tcs = Array.new()
	 
			#file = File.new ( "/home/charles/translation_test.xml")
			doc = REXML::Document.new self.epidoc

			
			transLanguage = "TEI.2/text/body/div[@type='translation']"
			transPath = "TEI.2/text/body/div[@type='translation']"
			
			REXML::XPath.each(doc, transPath) do |result| 
				transLanguage = result.attributes["lang"];      
			 
			 new_tc = TranslationContent.new()
			 new_tc.language = transLanguage     
		 
				REXML::XPath.each(result, "p") do |p_part|
					transDoc = REXML::Document.new(p_part.to_s)
					new_tc.content = transDoc.root.to_s			 
					
					#new_tc.content = p_part.to_s
					#just get the inner xml
					endIndex = new_tc.content.rindex("</p>")
					startIndex = new_tc.content.index("<p>")
					if endIndex && startIndex      	        
						startIndex = startIndex + 3
						subLength = endIndex - startIndex        
						new_tc.content = new_tc.content[startIndex, subLength]      
					else      	     
						#probably empty tag "<p/>"
						new_tc.content = ""
					end
					#new_tc.content = startIndex.to_s + " " + subLength.to_s + "  "+ endIndex.to_s      	
				end
		 #  new_tc.content = result.to_s
				#new_tc.language = transLanguage
				tcs << new_tc
			
			end
		rescue 
		# $!
		  success = false
		
		end  
   return success, tcs
  end
  
  #takes array of contents and inserts them into the Epidoc XML
  def PutTranslationsToEpidoc(translation_contents, forceOverwrite)

		begin
		
			translation_contents.each do |tc|
				if !PutTranslationToEpidoc(tc, forceOverwrite)				
					return false
				else
					forceOverwrite = false #since we just forced a new doc
				end
			end
			
		rescue  XmlCreationError
			raise $! #pass on the error
		end
			
 		return true
  end
  
  
  def PutTranslationToEpidoc(translation_content, forceOverwrite)

			#see if the lang is already in XML
			contentPath = "TEI.2/text/body/div[@type='translation'][@lang='"
			contentPath = contentPath + translation_content.language + "']"
		 			
			bodyPath = "TEI.2/text/body"			
			
			newDocText = "<TEI.2><text><body></body></text></TEI.2>"



			if (nil == self.epidoc) || ("" == self.epidoc) || forceOverwrite
			  
				#raise "chicken"
			  begin 
			  #raise "goat"
					doc = REXML::Document.new(newDocText)
				rescue
					raise XmlCreationError,   "Failed to create new xml."
				end			
			
			else
			
			
				begin
					doc = REXML::Document.new(self.epidoc)					
				rescue
					raise XmlCreationError,  "Cannot parse xml."
				end
				
			end
			
			#need to check that we are actually working with an epidoc
			if 0 == REXML::XPath.match(doc, bodyPath).length					
				raise XmlCreationError, "Incorrect path in xml."				
			end
			
		
		begin
	 #3 possibilities, 
	 #	1. content is just text, so it can be added via .text = 
	 #	2. content is XML, so it can be formated to XM and added as a node
	 #  3. content is mal formed XML ! then what?
	 
		 #enclose translation in p tag 
		 tempDoc = REXML::Document.new("<p>" + translation_content.content + "</p>")
				
			pathFound = false
	 
			#should only be one match for language
			REXML::XPath.each(doc, contentPath) do |result |
				pathFound = true
			 
				#remove previous elements
				result.each_element do |subElement|
					result.delete(subElement)
				end
				
				if (tempDoc)        
					result.add_element(tempDoc.root)               
				end
				\
			end
			
			if pathFound == false   
				newLang = REXML::Element.new("div");
				newLang.add_attribute("type", "translation")      
				newLang.add_attribute("lang", translation_content.language)
				
			 # newLang.add_text("<p>" + translation_content.content + "</p>")
				
				newContent = REXML::Element.new("p")
				newContent.add_text(translation_content.content)
				newLang.add_element(newContent)
				
				REXML::XPath.each(doc, bodyPath) do |result|
					result.add_element(newLang)       	    
				end         
			end
			
			self.epidoc = doc.to_s()  
			#raise "hi" +  self.epidoc  + "bye"  
		rescue
 			#raise $!.message
			return false
		
		end
			
			return true
  end
  
  #gets list of existing languages in epidoc
  def GetLanguagesInEpidoc()
    languages = Array.new()
    
    begin
			#file = File.new ( "/home/charles/translation_test.xml")
			doc = REXML::Document.new self.epidoc   
			
			transLanguage = "TEI.2/text/body/div[@type='translation']"    
			
			REXML::XPath.each(doc, transLanguage) do |result|     
				languages << result.attributes["lang"]        
			end
		rescue
			#just catch the exceptions, leave language array as is
		end
		  
    languages
  end
  
  #gets list of existing languages in translation_contents
  def GetLanguagesInTranslationContents()
    languages = Array.new()
    
    self.translation_contents.each do |tc|
      languages << tc.language
    end
    
    languages
  end
  
  
  def AddNewLanguageToTranslationContents(language)
  
    #check that it does not already exist
    lang_exist = false
    
    langs = GetLanguagesInTranslationContents()
    
    langs.each do |l|
      if l == language
        lang_exist = true
      end
    end
  
    if lang_exist == true
      return #do nothing it alread exist
    end
  
    #check that it is not already in the epidoc 
    #  and was not pulled out by error 
    #  is this needed?   
    langs = GetLanguagesInEpidoc()
  
    lang_exist = false
    langs.each do |l|
      if l == language
        lang_exist = true
      end
    end
  
    new_tc = nil
    if lang_exist == true
      #need to pull out of epidoc and put into translation_contents
      success, tcs = GetTranslationsFromEpidoc()
      tcs.each do |tc|
        if tc.language == language
          new_tc = tc
          #set new_tc to existing tc so we can add it to the database
        end
      end
    end
  
    if new_tc == nil    
    	new_tc = TranslationContent.new();
    	new_tc.language = language;
    	new_tc.content = ""    	
    end
    
    self.translation_contents << new_tc
    
    #no need to put into epidoc yet
  end
  
  
  
end
