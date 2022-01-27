# frozen_string_literal: true

class HGVTransGlossary < HGVTransIdentifier
  require 'rexml/document'
  include REXML

  require 'jruby_xml'

  class Entry
    attr_accessor :item, :term, :text

    def initialize(xml_item = nil, attributes_hash = nil)
      @text = {}

      read_xml_item(xml_item) unless xml_item.nil?

      unless attributes_hash.nil?
        @item = attributes_hash[:item]
        @term = attributes_hash[:term]
        @text = attributes_hash[:text]
      end
    end

    def read_xml_item(xml_item)
      # <item xml:id=" ">                term in latin chars?
      # <term xml:lang="grc"> </term>   term in greek chars
      # <gloss xml:lang=" "> </gloss>   definition repeated for multiple langs
      # </item>

      @item = xml_item.attributes['xml:id'] unless xml_item.attributes['xml:id'].nil?

      if !xml_item.elements['term'].nil? && xml_item.elements['term'].attributes['xml:lang'] == 'grc'
        @term = xml_item.elements['term'].text
      end

      xml_item.each_element('gloss') do |gloss|
        term_def = gloss.text
        lang = gloss.attributes['xml:lang']
        @text[lang] = term_def
      end
    end
  end

  LangCodes = %w[de en sp fr it la].freeze
  def self.lang_codes
    LangCodes
  end

  def to_path
    File.join(PATH_PREFIX, 'glossary.xml')
  end

  def delete_entry_in_file(item_id)
    doc = Document.new(content)

    doc.root.elements.delete("text/body/list/item[@xml:id='#{item_id}']")

    modified_xml_content = ''
    doc.write(modified_xml_content)
    set_content(modified_xml_content)
  end

  def add_entry_to_file(entry)
    glossary_entry = Entry.new(nil, entry)

    doc = Document.new(content)
    inserted = false

    # delete old item
    doc.root.elements.delete("text/body/list/item[@xml:id='#{glossary_entry.item}']")

    # add edited item
    # todo add in alphabetical order
    doc.root.each_element('text/body/list/item') do |itemNode|
      next unless !inserted && itemNode.attributes['xml:id'] == glossary_entry.item

      inserted = true

      itemNode.parent.insert_before(listNode, create_item_element(glossary_entry))
    end

    modified_xml_content = ''
    doc.write(modified_xml_content)
    set_content(modified_xml_content)
  end

  def self.create_item_element(glossaryEntry)
    itemElement = Element.new('item')
    itemElement.add_attribute('xml:id', glossaryEntry.item)

    termElement = Element.new('term')
    termElement.add_attribute('xml:lang', 'grc')

    itemElement.add_element(termElement)

    itemElement.elements['term'].text = glossaryEntry.term

    glossaryEntry.text.each do |lang, definition|
      itemElement.add_element(create_gloss_element(lang, definition)) unless definition.chomp.empty?
    end

    itemElement
  end

  def self.create_gloss_element(lang, definition)
    glossElement = Element.new('gloss')
    glossElement.add_attribute('xml:lang', lang)
    glossElement.add_text(definition.chomp)

    glossElement
  end

  def find_item(item_id)
    glossary_item = Entry.new

    doc = Document.new(content)

    glossary_item.item = item_id
    doc.root.each_element('text/body/list/item') do |item|
      glossary_item = Entry.new(item) if item_id == item.attributes['xml:id']
    end

    glossary_item
  end

  def xml_to_entries
    # formerly xmlToModel
    # read xml file

    doc = Document.new(content)

    # print doc

    # @glossaries << Glossary
    # root = doc.root

    # raise xmlFile.to_s()

    entries = []

    doc.root.each_element('text/body/list/item') do |item|
      # print item.attributes['xml:id']
      new_entry = Entry.new(item)
      entries << new_entry
    end

    # sort glossary entries
    entries.sort { |a, b| a.item.downcase <=> b.item.downcase }
  end

  def to_chooser
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(xml_content),
      JRubyXML.stream_from_file(File.join(Rails.root,
                                          %w[data xslt translation glossary_to_chooser.xsl]))
    )
  end
end
