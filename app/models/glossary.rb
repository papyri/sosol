class Glossary < ActiveRecord::Base

require 'rexml/document'
include REXML


def Glossary.deleteEntryInFile(itemId)

  xmlFile = File.new(File.join(RAILS_ROOT, 'data/xslt/translation/hgv-glossary.xml'), "r") #("hgv-glossary.xml")
  doc = Document.new(xmlFile)

  doc.root.elements.delete("text/body/list/item[@xml:id='" + itemId + "']")
  
  xmlFile.close
  xmlFile = File.new(File.join(RAILS_ROOT, 'data/xslt/translation/hgv-glossary.xml'), "w") #("hgv-glossary.xml")
  doc.write(xmlFile);
  xmlFile.close
  
end

def Glossary.addEntryToFile(entry)

  entryGlossary = Glossary.new(entry)
  
  xmlFile = File.new(File.join(RAILS_ROOT, 'data/xslt/translation/hgv-glossary.xml'), "r") #("hgv-glossary.xml")
  doc = Document.new(xmlFile)
  inserted = false
  
  #delete old item
  doc.root.elements.delete("text/body/list/item[@xml:id='" + entryGlossary.item + "']")
  
  #add edited item
  #todo add in alphebetical order
  doc.root.each_element('text/body/list') { |listNode|
    if (!inserted)
      inserted = true
      

      
      #listNode.parent.insert_before(listNode, itemNode)
      
      listNode.add_element(createItemElement( entryGlossary)) 
    end
  } 

  xmlFile.close
  xmlFile = File.new(File.join(RAILS_ROOT, 'data/xslt/translation/hgv-glossary.xml'), "w") 
  doc.write(xmlFile)
  xmlFile.close  
end
  
  
def Glossary.glossariesToXmlFile(glossaries)

  #open xmlfile
  xmlFile = File.new(File.join(RAILS_ROOT, 'data/xslt/translation/hgv-glossary.xml'), "r") #("hgv-glossary.xml")
  doc = Document.new(xmlFile)
  
  #delete all items
  doc.root.elements.delete_all("text/body/list/item")
  
  #sort glossary entries
  glossaries.sort! { |a,b| a.item.downcase <=> b.item.downcase }
  
  
  #put entries into xml
  listNode = doc.root.elements("text/body/list")
  glossaries.each { |glossary|
    listNode.add( createItemElement(glossary) )  
  }
  
  xmlFile.close
  xmlFile = File.new(File.join(RAILS_ROOT, 'data/xslt/translation/hgv-glossary.xml'), "w") 
  doc.write(xmlFile, 2)
  xmlFile.close

end
  
def Glossary.createItemElement(glossaryEntry)
      
      itemElement = Element.new("item")
      itemElement.add_attribute("xml:id", glossaryEntry.item)
      
      termElement = Element.new("term")
      termElement.add_attribute("xml:lang", "grc")
      
      itemElement.add_element(termElement)
      
      itemElement.elements["term"].text = glossaryEntry.term
      
      if glossaryEntry.en != nil && !glossaryEntry.en.chomp.empty? 
        itemElement.add_element( createGlossElement("en", glossaryEntry.en) )        
      end
      
      if glossaryEntry.de != nil && !glossaryEntry.de.chomp.empty? 
        itemElement.add_element( createGlossElement("de", glossaryEntry.de) )        
      end
      
      if glossaryEntry.fr != nil && !glossaryEntry.fr.chomp.empty? 
        itemElement.add_element( createGlossElement("fr", glossaryEntry.fr) )        
      end
      
      if glossaryEntry.sp != nil && !glossaryEntry.sp.chomp.empty? 
        itemElement.add_element( createGlossElement("sp", glossaryEntry.sp) )        
      end
      
      if glossaryEntry.la != nil && !glossaryEntry.la.chomp.empty? 
        itemElement.add_element( createGlossElement("la", glossaryEntry.la) )        
      end    
    
      itemElement
end
  
def Glossary.createGlossElement(lang, definition)

    glossElement = Element.new("gloss")
    glossElement.add_attribute("xml:lang", lang)
    glossElement.add_text(definition.chomp)
    
    glossElement  
end


def Glossary.findItem(itemId)

  glossary_item = Glossary.new()
  glossary_item.clear
  
    
   xmlFile = File.new(File.join(RAILS_ROOT, 'data/xslt/translation/hgv-glossary.xml'), "r") #("hgv-glossary.xml")
  doc = Document.new(xmlFile)
  
  glossary_item.item = itemId
  doc.root.each_element('text/body/list/item') { |item|
  
   if item.attributes['xml:id'] != nil && itemId == item.attributes['xml:id']
      glossary_item.item = item.attributes['xml:id']
    
      if  item.elements['term'] != nil && item.elements['term'].attributes['xml:lang'] == 'grc'
        #newGloss.grc = item.elements("term[@xml:lang='grc']")
        glossary_item.term = item.elements['term'].text
      end
      
      item.each_element('gloss') { |gloss|
        termDef = gloss.text
        
        lang = case gloss.attributes['xml:lang'] 
          when "en" then glossary_item.en = termDef
          when "de" then glossary_item.de = termDef
          when "fr" then glossary_item.fr = termDef
          when "sp" then glossary_item.sp = termDef
          when "la" then glossary_item.la = termDef                
        end    
      }    
    end
  }
  
  glossary_item

end


def Glossary.xmlToModel
  #read xml file
  
  xmlFile = File.new(File.join(RAILS_ROOT, 'data/xslt/translation/hgv-glossary.xml'), "r") #("hgv-glossary.xml")

  doc = Document.new(xmlFile)
  
  #print doc
  
  
  #@glossaries << Glossary 
  #root = doc.root 

  #raise xmlFile.to_s()
  
  glossaries = Array.new
  
  doc.root.each_element('text/body/list/item') { |item|
   #print item.attributes['xml:id']
    newGloss = Glossary.new()  
    newGloss.clear 
    if item.attributes['xml:id'] != nil
      newGloss.item = item.attributes['xml:id']
    end
    
    if  item.elements['term'] != nil && item.elements['term'].attributes['xml:lang'] == 'grc'
      #newGloss.grc = item.elements("term[@xml:lang='grc']")
      newGloss.term = item.elements['term'].text
    end
    
    item.each_element('gloss') { |gloss|
      termDef = gloss.text
      lang = case gloss.attributes['xml:lang'] 
        when "en" then newGloss.en = termDef
        when "de" then newGloss.de = termDef
        when "fr" then newGloss.fr = termDef
        when "sp" then newGloss.sp = termDef
        when "la" then newGloss.la = termDef                
      end    
    }    
    
    glossaries << newGloss    
  }
  
  #sort glossary entries
  glossaries.sort! { |a,b| a.item.downcase <=> b.item.downcase }
  glossaries

end

def clear
  self.item = ""
  self.term = ""
  self.en = ""
  self.de = ""
  self.fr = ""
  self.sp = ""
  self.la = ""
end


end
