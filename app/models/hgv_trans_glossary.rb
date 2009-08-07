class HGVTransGlossary < HGVTransIdentifier
  require 'rexml/document'
  include REXML

  class Entry
    attr_accessor :item, :term, :text

    def initialize(xml_item = nil, attributes_hash = nil)
      @text = Hash.new

      if !xml_item.nil?
        read_xml_item(xml_item)
      end

      if !attributes_hash.nil?
        @item = attributes_hash[:item]
        @term = attributes_hash[:term]
        @text = attributes_hash[:text]
      end
    end

    def read_xml_item(xml_item)
      if xml_item.attributes['xml:id'] != nil
        @item = xml_item.attributes['xml:id']
      end

      if  xml_item.elements['term'] != nil && xml_item.elements['term'].attributes['xml:lang'] == 'grc'
        #newGloss.grc = item.elements("term[@xml:lang='grc']")
        @term = xml_item.elements['term'].text
      end

      xml_item.each_element('gloss') { |gloss|
        term_def = gloss.text
        lang = gloss.attributes['xml:lang']
        @text[lang] = term_def
      }
    end
  end

  def to_path
    return File.join(PATH_PREFIX, 'glossary.xml')
  end

  def delete_entry_in_file(item_id)
    doc = Document.new(self.content)

    doc.root.elements.delete("text/body/list/item[@xml:id='" + item_id + "']")

    modified_xml_content = ''
    doc.write(modified_xml_content);
    self.set_content(modified_xml_content)
  end

  def add_entry_to_file(entry)

    glossary_entry = Entry.new(nil, entry)

    doc = Document.new(self.content)
    inserted = false

    #delete old item
    doc.root.elements.delete("text/body/list/item[@xml:id='" + glossary_entry.item + "']")

    #add edited item
    #todo add in alphebetical order
    doc.root.each_element('text/body/list') { |listNode|
      if (!inserted)
        inserted = true

        #listNode.parent.insert_before(listNode, itemNode)

        listNode.add_element(create_item_element(glossary_entry)) 
      end
    } 

    modified_xml_content = ''
    doc.write(modified_xml_content)
    self.set_content(modified_xml_content)
  end

  def HGVTransGlossary.create_item_element(glossaryEntry)
    itemElement = Element.new("item")
    itemElement.add_attribute("xml:id", glossaryEntry.item)

    termElement = Element.new("term")
    termElement.add_attribute("xml:lang", "grc")

    itemElement.add_element(termElement)

    itemElement.elements["term"].text = glossaryEntry.term

    glossaryEntry.text.each do |lang, definition|
      if !definition.chomp.empty?
        itemElement.add_element(create_gloss_element(lang, definition))
      end
    end

    itemElement
  end

  def HGVTransGlossary.create_gloss_element(lang, definition)
    glossElement = Element.new("gloss")
    glossElement.add_attribute("xml:lang", lang)
    glossElement.add_text(definition.chomp)

    glossElement  
  end


  def find_item(item_id)
    glossary_item = Entry.new()

    doc = Document.new(self.content)

    glossary_item.item = item_id
    doc.root.each_element('text/body/list/item') { |item|
      if item_id == item.attributes['xml:id']
        glossary_item = Entry.new(item)
      end
    }

    return glossary_item
  end

  def xml_to_entries
    # formerly xmlToModel
    #read xml file

    doc = Document.new(self.content)

    #print doc

    #@glossaries << Glossary 
    #root = doc.root 

    #raise xmlFile.to_s()

    entries = Array.new

    doc.root.each_element('text/body/list/item') { |item|
      #print item.attributes['xml:id']
      new_entry = Entry.new(item)
      entries << new_entry
    }

    #sort glossary entries
    return entries.sort { |a,b| a.item.downcase <=> b.item.downcase }
  end

end
