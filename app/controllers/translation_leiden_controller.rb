# frozen_string_literal: true

# No associated views - just call the methods to do Translation Leiden+ and XML conversions for translations
class TranslationLeidenController < ApplicationController
  # Transform Translation XML to Leiden+ - used in the Translation Helper menu - used in javascript ajax call
  # - *Params*  :
  #   - +xml+ -> Translation XML to transform to Leiden+
  # - *Returns* :
  #   - Leiden+
  # - *Rescue*  :
  #   - RXSugar::XMLParseError - formats and returns error message if transform fails
  def xml_to_translation_leiden
    xml2conv = params[:xml]
    begin
      leidenback = TranslationLeiden.xml_to_translation_leiden(xml2conv)

      render plain: leidenback.to_s
    rescue RXSugar::XMLParseError => e
      # insert **ERROR** into content to help user find it - subtract 1 for offset from 0
      e.content.insert((e.column - 1), '**ERROR**')
      render plain: xml2conv + "Error at column #{e.column} #{e.content}"
    end
  end

  # - Get the Leiden to insert a specific new language div in a translation
  # - *not* *in* *use* *currently*
  def get_language_translation_leiden
    lang = params[:lang]
    begin
      leidenback = TranslationLeiden.get_language_translation_leiden(lang)
      render plain: leidenback.to_s
    rescue RXSugar::XMLParseError => e
      # insert **ERROR** into content to help user find it - subtract 1 for offset from 0
      e.content.insert((e.column - 1), '**ERROR**')
      render plain: xml2conv + "Error at column #{e.column} #{e.content}"
    end
  end

  # Transform Translation Leiden+ to XML - used in the Translation Helper menu - used in javascript ajax call
  # - *Params*  :
  #   - +leiden+ -> Translation Leiden+ to transform to XML
  # - *Returns* :
  #   - XML
  # - *Rescue*  :
  #   - RXSugar::NonXMLParseError - formats and returns error message if transform fails
  def translation_leiden_to_xml
    leiden2conv = params[:leiden]
    begin
      xmlback = TranslationLeiden.translation_leiden_to_xml(leiden2conv)

      render plain: xmlback.to_s
    rescue RXSugar::NonXMLParseError => e
      # insert **ERROR** into content to help user find it - subtract 1 for offset from 0
      e.content.insert((e.column - 1), '**ERROR**')
      render plain: "Error at column #{e.column} #{e.content}"
    end
  end
end
