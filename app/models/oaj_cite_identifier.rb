
class OajCiteIdentifier < CiteIdentifier   
  include OacHelper
  require 'uuid'


  FRIENDLY_NAME = "Annotation (JSON-LD)"
  PATH_PREFIX="CITE_OA_JSON"
  FILE_TYPE="oac.json"


  ###########################################3
  # Public Instance Method Overrides
  ###########################################3

  # @overrides Identifier#is_valid_xml?
  # all content is considered valid
  # (but will be checked on commit)
  def is_valid_xml?(content)
    true
  end

  # @overrides Identifier#before_commit
  # Preprocesses content
  def before_commit(content)
    OajCiteIdentifier.preprocess(content)
  end

  # @overrides Identifier#preprocess
  # make sure it parses - it should raise an error if not
  def self.preprocess(content)
    JSON.parse(content)
    # force the content to utf-8
    content.force_encoding("utf-8")
  end
  
  # @overrides Identifier#after_rename
  # need to update the uris to reflect the new name
  def after_rename(options = {})
     raise "Rename not supported yet!"
  end

  # @overrides Identifier.mimetype
  def mimetype
    "application/ld+json"
  end

end
