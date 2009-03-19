require "rexml/document"

class Translation < ActiveRecord::Base
  belongs_to :article
  has_many :translation_contents
  
  
  
  #pull out translation sections from xml
  #return an array of translation_contents
  def GetTranslationsFromXML()
    tcs = Array.new()
    
    #file = File.new ( "/home/charles/translation_test.xml")
    doc = REXML::Document.new self.content
    #not that his will come from the content not from a files

    
    transLanguage = "TEI.2/text/body/div[@type='translation']"
    transPath = "TEI.2/text/body/div[@type='translation']"
    
    REXML::XPath.each(doc, transPath) do |result| 
      transLanguage = result.attributes["lang"];
      
 
      #can do new path on result?
     new_tc = TranslationContent.new()
      REXML::XPath.each (result, "p") do |p_part|
      	new_tc.content = p_part()
      end
   #  new_tc.content = result.to_s
      new_tc.language = transLanguage
      tcs << new_tc
    
    end
  
   tcs
  end
  
  #takes array of contents and inserts them into the XML
  def PutTranslationsToXML(translation_contents)
    translation_contents.each do |tc|
      PutTranslationToXML(tc)
 	end
  end
  
  
  def PutTranslationToXML(translation_content)
    #see if the lang is already in XML
    contentPath = "TEI.2/text/body/div[@type='translation'][@lang='"
    contentPath = contentPath + translation_content.language + "']"
    
    
    bodyPath = "TEI.2/text/body"
    
    doc = REXML::Document.new self.content
    
 #   newElement = REXML::Element.new("found")
 #   newElement.add_text( contentPath )
 
 
 #2 possibilities, 
 #	1. content is just text, so it can be added via .text = 
 #	2. content is XML, so it can be formated to XM and added as a node
 #  3. content is mal formed XML ! then what?
 
   tempDoc = REXML::Document.new(translation_content.content)
   if (tempDoc)
   # it is valid xml, so add it as node
   
   else
   #it is not so add it as text
   
   
   end
   
      
    pathFound = false
 
    REXML::XPath.each(doc, contentPath) do |result |
      pathFound = true
      #doc.root.add_element(newElement)
      #result = REXML::Element.new()
      
      #remove previous 
      result.each_element do |subElement|
        result.delete(subElement)
      end
      
      if (tempDoc)
        
        result.add_element(tempDoc.root)
        else
      result.text = translation_content.content       
      end
    end
    
    if pathFound == false   
      newLang = REXML::Element.new("div");
      newLang.add_attribute("type", "translation")      
      newLang.add_attribute("lang", translation_content.language)
      newLang.add_text(translation_content.content + "notfound")
            
      REXML::XPath.each(doc, bodyPath) do |result|
      	result.add_element(newLang)       	    
      end         
    end
    
    self.content = doc.to_s()    
  
  end
  
  #gets list of exiting languages in translation
  def GetLanguages()
    languages = Array.new()
    
    #file = File.new ( "/home/charles/translation_test.xml")
    doc = REXML::Document.new self.content
    #not that his will come from the content not from a files
    
    transLanguage = "TEI.2/text/body/div[@type='translation']"    
    
    REXML::XPath.each(doc, transLanguage) do |result|     
      languages << result.attributes["lang"]        
    end
  
    languages
  end
  
  
  
  
  def AddNewLanguageToContent(language)
    tc = TranslationContent.new();
    tc.language = language;
    #no content yet
    PutTranslationToXML(tc)
  end
end
