# encoding: utf-8

# - Sub-class of Identifier
# - Includes acts_as_leiden_plus defined in vendor/plugins/rxsugar/lib/jruby_helper.rb
class SyriacaPersonIdentifier < SyriacaIdentifier

  PATH_PREFIX = 'Syriaca_Data'
  FRIENDLY_NAME = "Syriaca Person Gazetteer"
  IDENTIFIER_NAMESPACE = 'http://syriaca.org'
  TEMPORARY_COLLECTION = 'person'
  XML_VALIDATOR = JRubyXML::SyriacaGazetteerValidator
  NS_TEI = "http://www.tei-c.org/ns/1.0"

  # retrieve the remote path for finalization
  # eventually this should be found in the metadata
  # in the identifier contents
  def to_remote_path
    type, id = self.to_components[3..-1]
    "data/persons/tei/#{id}.xml"
  end
end
