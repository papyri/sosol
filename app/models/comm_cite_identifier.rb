class CommentaryCiteIdentifier < CiteIdentifier   
  include OacHelper


  FRIENDLY_NAME = "Commentary Annotation"
  PATH_PREFIX="CITE_COMMENTARY_XML"
  FILE_TYPE="oac.xml"
  ANNOTATION_TITLE = "Commentary Annotation"
  
  MAX_WORDS = -1
  #XML_VALIDATOR = JRubyXML::OacMarkdownValidator
  
  def titleize
    # TODO should say Commentary on Target URI
    title = self.name
    return title
  end
  
  def add_change_desc(text = "", user_info = self.publication.creator, input_content = nil)
    # this is a no-op because change desc is not added to this file
    # need to override to ensure consistent formatting of XML for all commits
    toXmlString self.rdf
  end
  
   # return the RDF of the oac.xml as an REXML::Document
  def rdf
    @rdfDocX ||= REXML::Document.new(self.xml_content)
  end
 
  # Commits identifier XML to the repository.
  # Overrides Identifier#set_content to reset memoized value set in OACIdentifier#rdf.
  # - *Args*  :
  #   - +content+ -> the XML you want committed to the repository
  #   - +options+ -> hash of options to pass to repository (ex. - :comment, :actor)
  # - *Returns* :
  #   - a String of the SHA1 of the commit
  def set_content(content, options = {})
    @rdfDocX = nil
    super
  end
  
  #initialization method for a new version of an existing CITE Object
  def init_version_content(a_content)
    annotation = OacHelper::add_annotator(REXML::Document.new(a_content),make_annotator_uri())
    oacRdf = toXmlString annotation
    self.set_xml_content(oacRdf, :comment => 'Initializing Content')
  end
  
  # make a annotator uri from the owner of the publication 
  def make_annotator_uri()
    ActionController::Integration::Session.new.url_for(:host => SITE_USER_NAMESPACE, :controller => 'user', :action => 'show', :user_name => self.publication.creator.id, :only_path => false)
  end
  
  # Converts REXML::Document / ::Element into xml string
  # - *Args*  :
  #   - +xmlObject+ → REXML::Document / ::Element
  # - *Returns* :
  #   - +String+ formatted xml string using child class PrettySsime of parent class +REXML::Formatters::Pretty+
  def toXmlString xmlObject
    formatter = PrettySsime.new
    formatter.compact = true
    formatter.width = 2**32
    modified_xml_content = ''
    formatter.write xmlObject, modified_xml_content
    modified_xml_content
  end
  
  # get the requested annotation by uri from the oac.xml 
  def get_annotation()
    xpath = "/rdf:RDF/oac:Annotation"
    REXML::XPath.first(self.rdf, xpath)          
  end

  def init_content(a_value)
    # the init value must be one or more target uris
    # todo calculate body URI and body as text
    annot_uri = SITE_CITE_COLLECTION_NAMESPACE + "/" + self.urn_attribute
    body_uri = annot_uri + "/commentary"
  
    atts = {}
    atts['uri'] = annot_uri
    atts['target_uris'] = a_value.split(/,/)
    atts['body_uri'] = body_uri
    atts['annotator_uri'] = make_annotator_uri()

    # defaults
    atts['motivation'] = "http://www.w3.org/ns/oa#commenting"  
    
    self.rdf.root.add_element(OacHelper::make_text_annotation(atts))
    # calling toXmlString to ensure consistent formatting throughout lifecycle of the file
    oacRdf = toXmlString self.rdf
    self.set_xml_content(oacRdf, :comment => 'Initializing Content')
  end
  
  def update_commentary(a_lang,a_text)
    OacHelper::update_body_text(self.rdf,a_lang,a_text)
  end
  
  # Place any actions you always want to perform on  identifier content prior to it being committed in this method
  # - *Args*  :
  #   - +content+ -> CommentaryCiteIdentifier XML as string
  def before_commit(content)
    CommentaryCiteIdentifier.preprocess(content)
  end
  
  # Applies the preprocess XSLT to 'content'
  # - *Args*  :
  #   - +content+ -> XML as string
  # - *Returns* :
  #   - modified 'content'
  def self.preprocess(content)
    #  this is where we can apply a word count limit
    #  transform can check language and apply tokenization 
    #  rules per language
    #  default for base class is to allow any word length so 
    #  will just return the original content 
    return content
  end
  

  ## method which checks the cite object for an initialization  value
  def is_match?(a_value) 
    # for a commentary annotation, the match will be on the target uri
    has_all_targets = true
    a_value.split(/,/).each do |uri|
      has_target = OacHelper::has_target?(self.rdf,uri)
      if (! has_target) 
        has_all_targets = false
      end 
    end
    return has_all_targets
  end
  
  ## TODO
  def is_valid_xml?(content)
    return true
  end
end