# encoding: utf-8

# - Sub-class of Identifier
class SyriacaWorkIdentifier < SyriacaIdentifier

  PATH_PREFIX = 'Syriaca_Data'
  FRIENDLY_NAME = "Syriaca Work Record"
  IDENTIFIER_NAMESPACE = 'http://syriaca.org'
  TEMPORARY_COLLECTION = 'work'
  XML_VALIDATOR = JRubyXML::SyriacaGazetteerValidator
  NS_TEI = "http://www.tei-c.org/ns/1.0"

  # retrieve the remote path for finalization
  # eventually this should be found in the metadata
  # in the identifier contents
  def to_remote_path
    type, id = self.to_components[3..-1]
    "data/works/tei/#{id}.xml"
  end
end
