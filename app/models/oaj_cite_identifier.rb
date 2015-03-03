class OajCiteIdentifier < CiteIdentifier   
  include OacHelper
  require 'uuid'


  FRIENDLY_NAME = "Annotation"
  PATH_PREFIX="CITE_OA_JSON"
  FILE_TYPE="oac.json"
  ANNOTATION_TITLE = "Annotation"
  
  def titleize
    title = self.name
    return title
  end

  def self.new_from_supplied(a_publication,a_urn,a_init_content)
    temp_id = self.new(:name => self.next_version_identifier(a_urn))
    temp_id.publication = a_publication 
    temp_id.save!
    Rails.logger.info("initial content #{a_init_content}")
    temp_id.set_xml_content(a_init_content, :comment => 'Created from Supplied content', :validate => true )
    return temp_id
  end

  def is_valid_xml?(content)
    true
  end

  def before_commit(content)
    OajCiteIdentifier.preprocess(content)
  end

  def self.preprocess(content)
    # make sure it parses - it should raise an error if not
    JSON.parse(content)
    content
  end
  
  ## method which checks the cite object for an initialization  value
  def is_match?(a_value) 
    # for general OA Annotations we allow multiple on the same target 
    return false
  end
  
  def preview parameters = {}, xsl = nil
    JSON.pretty_generate(JSON.parse(self.content))
  end
  
  # need to update the uris to reflect the new name
  def after_rename(options = {})
     raise "Rename not supported yet!"
  end

end
