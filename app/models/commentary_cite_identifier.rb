class CommentaryCiteIdentifier < CiteIdentifier   
  include OacHelper


  FRIENDLY_NAME = "Commentary Annotation"
  PATH_PREFIX="CITE_COMMENTARY_XML"
  FILE_TYPE="oac.xml"
  ANNOTATION_TITLE = "Commentary Annotation"
  
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
    ActionController::Integration::Session.new(Sosol::Application).url_for(:host => SITE_USER_NAMESPACE, :controller => 'user', :action => 'show', :user_name => self.publication.creator.name, :only_path => false)
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
   OacHelper::get_first_annotation(self.rdf)         
  end
  
  def language()
    OacHelper::get_body_language(get_annotation)
  end

  def init_content(a_value)
    # the init value must be one or more target uris
    # todo calculate body URI and body as text
    annot_uri = SITE_CITE_COLLECTION_NAMESPACE + "/" + self.urn_attribute
    body_uri = annot_uri + "/commentary"
  
    atts = {}
    atts['uri'] = annot_uri
    atts['target_uris'] = a_value
    atts['body_uri'] = body_uri
    # TODO support user default for commentary language
    atts['body_language'] = 'eng'
    atts['annotator_uri'] = make_annotator_uri()

    # defaults
    atts['motivation'] = "http://www.w3.org/ns/oa#commenting"  
    
    self.rdf.root.add_element(OacHelper::make_text_annotation(atts))
    # calling toXmlString to ensure consistent formatting throughout lifecycle of the file
    oacRdf = toXmlString self.rdf
    self.set_xml_content(oacRdf, :comment => 'Initializing Content')
  end
  
  def get_commentary_text()
    OacHelper::get_body_text(get_annotation)
  end
  
  def update_commentary(a_lang,a_text,a_comment)
    OacHelper::update_body_text(get_annotation,a_lang,a_text)
    oacRdf = toXmlString self.rdf
    # TODO should either update annotatedAt or set updatedAt (does that exist??)
    self.set_xml_content(oacRdf, :comment => a_comment)
  end
  
  # Place any actions you always want to perform on  identifier content prior to it being committed in this method
  # - *Args*  :
  #   - +content+ -> CommentaryCiteIdentifier XML as string
  def before_commit(content)
    CommentaryCiteIdentifier.preprocess(self.urn_attribute,content)
  end
  
  # Applies the preprocess XSLT to 'content'
  # - *Args*  :
  #   - +content+ -> XML as string
  # - *Returns* :
  #   - modified 'content'
  def self.preprocess(urn,content)
    #  this is where we can apply a word count limit
    #  transform can check language and apply tokenization 
    #  rules per language
    #  default for base class is to allow any word length so 
    #  will just return the original content
    max = Cite::CiteLib.get_collection_field_max(urn)
    # -1 or undefined means no limit
    if (max.nil? || max < 0) 
      return content
    else
      passed = JRubyXML.apply_xsl_transform(
        JRubyXML.stream_from_string(content),
        JRubyXML.stream_from_file(File.join(Rails.root,
          %w{data xslt cite markdown_field_verify.xsl})),
          :e_max => max)
      if (passed == 'true')
        return content  
      elsif (passed == 'error')
        raise Cite::CiteError.new("Unable to process commentary text.")
      else 
        raise Cite::CiteError.new("Commentary text has #{passed} words, which exceeds the maximum of #{max}.")
     end
   end
  end
  

  ## method which checks the cite object for an initialization  value
  def is_match?(a_value) 
    # for a commentary annotation, the match will be on the target uri
    has_all_targets = true
    a_value.each do |uri|
      has_target = OacHelper::has_target?(get_annotation,uri)
      if (! has_target) 
        has_all_targets = false
      end 
    end
    return has_all_targets
  end
  
  def preview_targets parameters = {}, xsl = nil
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(self.xml_content),
      JRubyXML.stream_from_file(File.join(Rails.root,
        xsl ? xsl : %w{data xslt cite commentary_cite_targets.xsl})),
        parameters)
  end
  
  def preview parameters = {}, xsl = nil
    # TODO 
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(self.xml_content),
      JRubyXML.stream_from_file(File.join(Rails.root,
        xsl ? xsl : %w{data xslt cite commentary_cite_html_preview.xsl})),
        parameters)
  end
  
  ## TODO
  def is_valid_xml?(content)
    return true
  end
  
  # need to update the uris to reflect the new name
  def after_rename(options = {})
    annot_uri = SITE_CITE_COLLECTION_NAMESPACE + "/" + self.urn_attribute
    body_uri = annot_uri + "/commentary"
    OacHelper::update_annotation_uris(get_annotation,annot_uri,body_uri)
    oacRdf = toXmlString self.rdf
    # TODO should either update annotatedAt or set updatedAt (does that exist??)
    self.set_xml_content(oacRdf, :comment => 'Update uris to reflect new identifier')
  end
end
