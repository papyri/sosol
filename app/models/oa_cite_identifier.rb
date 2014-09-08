class OaCiteIdentifier < CiteIdentifier   
  include OacHelper


  FRIENDLY_NAME = "Annotation"
  PATH_PREFIX="CITE_OA_XML"
  FILE_TYPE="oac.xml"
  ANNOTATION_TITLE = "Annotation"
  XML_VALIDATOR = JRubyXML::RDFValidator
  
  def titleize
    title = self.name
    return title
  end

  def self.new_from_template(a_publication,a_urn,a_init_value)
    # special handling for google spreadsheet urls as init value
    # temporary hack -- we should use google apis for google drive 
    # integration and configure google as a full fledged agent
    agent = nil
    a_init_value.each do | a_url |
      agent = AgentHelper.agent_of(a_url)
    end
    # TODO this is problematic if init_value is an agent url that is
    # just poorly formed.  The input form should prevent that but 
    # might not always
    if agent.nil?
      return super(a_publication,a_urn,a_init_value)
    end

    transform = agent[:transformations][:OaCiteIdentifier]
    worksheet_idmatch = nil
    a_init_value.each do |a_url|
      # TODO This nonsense should be replaced by use of google api
      worksheet_idmatch = a_url.match(/key=([^&;\s]+)/) || # old style url
        a_url.match(/\/([^\/]+)\/(pubhtml|edit)/) # newer url
      if worksheet_idmatch
        break;
      end
    end
    unless (worksheet_idmatch) 
        raise "Invalid URL: Unable to parse spreadsheet id from #{a_init_value.inspect}"
    end

    worksheet_id = worksheet_idmatch.captures[0] 
    uri = agent[:get_url].sub(/WORKSHEET_ID/,worksheet_id)
    uri = URI.parse(uri)
    Rails.logger.info("Getting content from #{uri}")
    response = Net::HTTP.start(uri.host, uri.port) do |http|
      http.send_request('GET',uri.request_uri)
    end
    unless (response.code == '200')
      raise "Unable to retreive content from #{uri}"
    end
    
    temp_id = self.new(:name => self.next_object_identifier(a_urn))
    temp_id.publication = a_publication 
    if (! temp_id.collection_exists?)
      raise "Unregistered CITE Collection for #{a_urn}"
    end
    temp_id.save!
    content = JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(response.body),
      JRubyXML.stream_from_file(File.join(RAILS_ROOT,transform)),
      :e_agentUri => agent[:uri_match],
      :e_annotatorUri => temp_id.make_annotator_uri,
      :e_annotatorName => temp_id.publication.creator.human_name,
      :e_baseAnnotUri => SITE_CITE_COLLECTION_NAMESPACE + "/" + temp_id.urn_attribute 
    )  
    temp_id.set_content(content, :comment => "Created from #{a_init_value.inspect}")
    return temp_id
  end
  
  def add_change_desc(text = "", user_info = self.publication.creator, input_content = nil)
    # TODO prov tracking of annotations
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
    ActionController::Integration::Session.new.url_for(:host => SITE_USER_NAMESPACE, :controller => 'user', :action => 'show', :user_name => self.publication.creator.name, :only_path => false)
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
  def get_annotations()
   OacHelper::get_all_annotations(self.rdf)         
  end
  
  def init_content(a_value)
    # the init value must be one or more target uris
    # todo calculate body URI and body as text
    annot_uri = SITE_CITE_COLLECTION_NAMESPACE + "/" + self.urn_attribute + "#1"
    targets = []
    if (a_value.nil?) 
      targets.concat([''])
    else 
      targets.concat(a_value)
    end 
    self.rdf.root.add_element(OacHelper::make_annotation(annot_uri,targets,[''],"http://www.w3.org/ns/oa#linking", make_annotator_uri(),nil))
    # calling toXmlString to ensure consistent formatting throughout lifecycle of the file
    oacRdf = toXmlString self.rdf
    self.set_xml_content(oacRdf, :comment => 'Initializing Content')
  end
  
  # Place any actions you always want to perform on  identifier content prior to it being committed in this method
  # - *Args*  :
  #   - +content+ -> OaCiteIdentifier XML as string
  def before_commit(content)
    OaCiteIdentifier.preprocess(self.urn_attribute,content)
  end
  
  # Applies the preprocess XSLT to 'content'
  # - *Args*  :
  #   - +content+ -> XML as string
  # - *Returns* :
  #   - modified 'content'
  def self.preprocess(urn,content)
    # TODO check for missing data?
    return content
  end
  

  ## method which checks the cite object for an initialization  value
  def is_match?(a_value) 
    # for general OA Annotations we allow multiple on the same target 
    return false
  end
  
  def preview_targets parameters = {}, xsl = nil
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(self.xml_content),
      JRubyXML.stream_from_file(File.join(Rails.root,
        xsl ? xsl : %w{data xslt cite oa_cite_targets.xsl})),
        parameters)
  end
  
  def preview parameters = {}, xsl = nil
    # TODO 
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(self.xml_content),
      JRubyXML.stream_from_file(File.join(Rails.root,
        xsl ? xsl : %w{data xslt cite oa_cite_preview.xsl})),
        parameters)
  end
  
  # need to update the uris to reflect the new name
  def after_rename(options = {})
     raise "Rename not supported yet!"
  end
  
  def can_update?(a_orig,a_new)
    session_owner = make_creator_uri()
    
    authorized_owner =
      # either the original creator is the session owner 
      OacHelper::get_creator(a_orig) == session_owner ||
      # or own of the annotators is the session owner 
      (OacHelper::get_annotators(a_orig).include?(session_owner)) ||
      # or the publication is being finalized, in which case the session owner is not necessarily an annotator
      # TODO in case of changes during finalization, the finalizer should be added as an annotator 
      @publication.status == 'finalizing'
    orig_agents = OacHelper::get_software_agents(a_orig)
    new_agents = OacHelper::get_software_agents(a_new)
    
    authorized_agent =
      # if no previous agent, then anyone is authorized to update 
      orig_agents.size == 0 ||
      # otherwise there must be at least one common agent between the original and the updated 
      (orig_agents & new_agents).size > 0
    return authorized_agent && authorized_owner
      
  end
end
