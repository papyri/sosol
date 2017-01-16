## 
# model class is @deprecated
# use oa_cite_identifier instead
# 
require 'uri'

class OACIdentifier < Identifier  
  # This is a base class for OAC Annotations.
  include OacHelper

  PATH_PREFIX = 'XML_OAC'
  IDENTIFIER_NAMESPACE = 'oac'
  FRIENDLY_NAME = 'Text Annotations'
  TEMPORARY_COLLECTION = 'TempAnnotations'
  TEMPORARY_TITLE = 'Annotations'
  XML_VALIDATOR = JRubyXML::RDFValidator

  NS_RDF = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  NS_DCTERMS = "http://purl.org/dc/terms/"  
  NS_FOAF = "http://xmlns.com/foaf/0.1/"  
  NS_OAC = "http://www.w3.org/ns/oa#" 
  
  
  def get_catalog_link
   # no catalog for annotations right now
   return []
  end
  
  def titleize
    "Annotations"
  end
  
  def add_change_desc(text = "", user_info = self.publication.creator, input_content = nil, timestamp = Time.now.xmlschema)
    # this is a no-op because change desc is not added to this file
    # need to override to ensure consistent formatting of XML for all commits
    toXmlString self.rdf
  end
  
  # find this identifier from its parent identifier
  def self.find_from_parent(publication,parent)
    temp_name = make_name(parent.name)
    publication.identifiers.select{|item|(item.name == temp_name) && item.kind_of?(OACIdentifier)}.last
  end
  
  def self.make_name(parentName)
    parentName.clone + "/annotations"
  end
  
  # create a new file to hold the annotations for the supplied publication and parent text
  def self.new_from_template(publication,parent)
    temp_name = make_name(parent.name) 
    temp_id = self.new(:name => temp_name)
    temp_id.publication = publication
    temp_id.title = "Annotations for #{parent.title}"
    initial_content = temp_id.file_template
    temp_id.set_xml_content(initial_content,:comment => 'New Annotations Template')
    temp_id.save!
    return temp_id
  end
  
  # return identifier value formatted for  use for an XML id attribute
  def id_attribute 
    self.to_components.join('.')
  end
  
  # return identifier value formatted for use an an XML n attribute
  def n_attribute 
    self.to_components.join('.')
  end
  
  # return the title text
  def xml_title_text
    self.id_attribute
  end
  
  # find the identifier for the parent text for this annotation
  def parentIdentifier 
    parent_name = self.name.clone.sub!(/\/annotations$/, '')
    publication = self.publication
    parent_id = publication.identifiers.select{|item|item.name == parent_name}
    if (parent_id.length != 1)
        raise "Error retrieving parent identifier #{parent_name}. Found #{parent_id.length}."
    end
    return parent_id[0]
  end
  
  # path to oac identifiers
  def to_path
    return self.class::PATH_PREFIX + "/" + self.name + "/oac.xml"
  end
  
  # test to see if any annotations have been added to the oac.xml file yet
  def has_anyannotation?()
    all = OacHelper::get_all_annotations(self.rdf)
    hasany = false
    begin
      if ! all.first.nil?
        hasany = true
      end
    rescue Exception => e
      ## TODO?
      Rails.logger.error("Error checking for annotation #{e.to_s}")
    end      
    return hasany
  end
    
  # get the requested annotation by uri from the oac.xml 
  def get_annotation(a_uri)
   OacHelper::get_annotation(self.rdf,a_uri)          
  end
  
  def get_annotations()
    OacHelper::get_annotations_by_annotator(self.rdf,make_creator_uri())
  end
  
  # look for Annotations whose target resource matches the targetUriMatch string
  # targeUriMatch is expected to be a properly quoted regex string
  def matching_targets(targetUriMatch,creatorUri)
    matches = []
    Rails.logger.info("ALL #{OacHelper::get_all_annotations(self.rdf).inspect}")
    OacHelper::get_all_annotations(self.rdf).each() { |el|
      Rails.logger.info("checking #{OacHelper::get_creator(el)}")
      if (OacHelper::get_creator(el) == creatorUri || OacHelper::get_annotators(el).include?(creatorUri)) 
        annot_id = el.attributes['rdf:about']
        OacHelper::get_targets(el).each() { |tgt|
          Rails.logger.info("Comparing #{tgt} to #{targetUriMatch}")
          if tgt =~ /#{targetUriMatch}/ 
            Rails.logger.info("Matched")
            match = Hash.new
            match['id'] = annot_id
            match['target'] = tgt
            matches << match   
          end
        }
      end
    }
    return matches
  end
  
  # check to see if the supplied target is already used for any of the annotations owned by the requesting user
  ## USED ONLY IN TESTS NEEDS TO BE REDONE FOR NAMESPACE
  def has_target?(targetUri,creatorUri)
    has_target = false
    self.get_annotations().each do |a_annot|
      Rails.logger.info("Checking #{toXmlString a_annot} for #{targetUri}")
      xpath = "//oa:hasTarget[@rdf:resource = '#{targetUri}']]"
      if (REXML::XPath.match(a_annot, xpath, {"oa" => NS_OAC}).size > 0) 
           has_target = true
      end
    end
    return has_target
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
  
  # create a new annotation with an empty body
  def create_annotation(a_target_uri)
    annot_uri = next_annotation_uri()
    add_annotation(annot_uri,[a_target_uri],[],nil,make_creator_uri(),nil,"Create")
    return annot_uri
  end
  
  # update a pre-existing annotation in the oac.xml file
  def update_annotation(annot_uri,target_uris,body_uris,motivation,creator_uri,agents,comment)
    annot = OacHelper::get_annotation(self.rdf,annot_uri) 
    Rails.logger.info("Before update #{toXmlString annot}")
    if (annot.nil?)
      Rails.logger.info("Not found #{annot_uri}")
      Rails.logger.info(toXmlString self.rdf)
      raise "Unable to find #{annot_uri}."
    end
    annot.elements.delete_all '*'
    target_uris.each do |uri|
      annot.add_element(OacHelper::make_target(uri))
    end
    body_uris.each do |uri|
      annot.add_element(OacHelper::make_body(uri))
    end
    annot.add_element(OacHelper::make_motivation(motivation))
    annot.add_element(OacHelper::make_annotator(creator_uri))
    unless (agents.nil?)
      agents.each do | a_agent | 
        annot.add_element(OacHelper::make_software_agent(a_agent))
      end
    end
    annot.add_element(OacHelper::make_annotated_at)
    Rails.logger.info("After update #{toXmlString annot}")
    # calling toXmlString to ensure consistent formatting throughout lifecycle of the file
    oacRdf = toXmlString self.rdf
    self.set_xml_content(oacRdf, :comment => comment)
  end
  
  # add a new annotation to the oac.xml file
  def add_annotation(annot_uri,target_uris,body_uris,motivation,creator_uri,agent,comment)
    exists = OacHelper::get_annotation(self.rdf,annot_uri)
    unless (exists.nil?)
      raise "An annotation identified by #{annot_uri} already exists."
    end
    self.rdf.root.add_element(OacHelper::make_annotation(annot_uri,target_uris,body_uris,motivation,creator_uri,agent))
    # calling toXmlString to ensure consistent formatting throughout lifecycle of the file
    oacRdf = toXmlString self.rdf
    self.set_xml_content(oacRdf, :comment => comment)
  end
  
  # delete an existing annotation from the oac.xml file
  def delete_annotation(annot_uri,comment)
    OacHelper::remove_annotation(self.rdf,annot_uri)
    unless (OacHelper::get_annotation(self.rdf,annot_uri).nil?)
      raise "Unable to delete #{annot_uri} still have #{OacHelper::get_annotation(self.rdf,annot_uri)}."
    end
    # calling toXmlString to ensure consistent formatting throughout lifecycle of the file
    oacRdf = toXmlString self.rdf
    self.set_xml_content(oacRdf, :comment => comment)
  end
  
  
  # make a creator uri from the owner of the publication 
  def make_creator_uri()
    "#{Sosol::Application.config.site_user_namespace}#{URI.escape(self.publication.creator.name)}"
  end
  
  # find the next annotation uri for appending to the oac.xml
  def next_annotation_uri() 
    # I'm not sure if this is a reasonably generic and scalable approach
    # it current creates the uri by joining the following each as path elements:
    #  1. site-specific namespace for oac annotations
    #  2. publication id
    #  3. publication id
    #  4. text id
    #  5. oac identifier id
    #  6. publication owner id (i.e. user creating the annotation)
    #  7. sequential #
    # A question is what do we do when we get multiple sosol instances all wanting to collaborate on the
    # same files.  For now, I'm assuming we can address this by setting the config.site_user_namespace to an instance
    # specific string (e.g. http://data.perseus.org/annotations/sosol1/) but this may not be a good
    # approach for a distributed environment. 
    max = 1
    all = OacHelper::get_all_annotations(self.rdf)
    all.each { |el|
      annot_id = el.attributes['rdf:about']
      num_this_creator = annot_id.split(/\//).last.to_i
      if (num_this_creator > max)
        max = num_this_creator
      end
    }
    next_num = max+1
    return "#{Sosol::Application.config.site_oac_namespace}/#{self.publication.id}/#{self.parentIdentifier.id}/#{self.id}/#{self.publication.owner.id}/#{next_num}" 
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
  
  # transform the oac annotation to an html display
  # if the annotation_uri parameter is supplied, it will transform the contents
  # of the requested annotation_uri only.
  # if the annotation_uri parameter is not supplied, it will provide a list of links to preview
  # each annotation in the oac.xml file 
  def preview parameters = {}, xsl = nil
    parameters[:tool_url] =Tools::Manager.link_to('oa_editor',:perseids,:view,[self])[:href] 
    parameters[:lang] = self.parentIdentifier.lang
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(self.xml_content),
      JRubyXML.stream_from_file(File.join(Rails.root,
        xsl ? xsl : %w{data xslt oac html_preview.xsl})),
        parameters)
  end
  
   # edit 
  # outputs the sentence list with sentences linked to editor
  def edit parameters = {}, xsl = nil
    parameters[:tool_url] = Tools::Manager.link_to('oa_editor',:perseids,:edit,[self])[:href]
    parameters[:lang] = self.parentIdentifier.lang
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(self.xml_content),
      JRubyXML.stream_from_file(File.join(Rails.root,
        xsl ? xsl : %w{data xslt oac html_preview.xsl})),
        parameters)
  end
  
  # api_get responds to a call from the data management api controller
  # @param [String] a_query if not nil, means use the query to 
  #                         return part of the item
  def api_get(a_query)
    # query will contain the uri of the annotation
    if (a_query)
      qmatch = /^uri=(.*?)$/.match(a_query)
      if (qmatch.nil?)
        raise "Invalid request - no uri specified in #{a_query}"
      else
        return toXmlString get_annotation(qmatch[1])
      end
    else
      return toXmlString get_annotations()
    end
      
  end
  
  # api_append responds to a call from the data management api controller
  # @param [String] a_body the raw body of the post data
  # @param [String] a_comment an update comment
  #
  def api_append(a_agent,a_body,a_comment)
    transform = nil
    if (! a_agent.nil? && a_agent[:transformations][:OACIdentifier])
      transform = a_agent[:transformations][:OACIdentifier]
    end
    if (transform.nil?)
      oac = a_body
    else
      oac = JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(a_body),
      JRubyXML.stream_from_file(File.join(Rails.root, transform)))  
    end
    annot_uri = next_annotation_uri()
    annot = REXML::Document.new(oac).root
    target_uris = OacHelper::get_targets(annot)
    body_uris = OacHelper::get_bodies(annot)
    motivation = OacHelper::get_motivation(annot)
    swagents = OacHelper::get_software_agents(annot)
    add_annotation(annot_uri,target_uris,body_uris,motivation,make_creator_uri(),swagents[0],a_comment)
    return annot_uri
  end
  
  # api_update responds to a call from the data management api controller
  # @param [String] a_query  parameter containing a querystring
  #                 specific to the identifier type. 
  # @param [String] a_body the raw body of the post data
  # @param [String] a_comment an update comment
  #
  def api_update(a_agent,a_query,a_body,a_comment)
    transform = nil
    if (! a_agent.nil? && a_agent[:transformations][:OACIdentifier])
      transform = a_agent[:transformations][:OACIdentifier]
    end
    if (transform.nil?)
      oac = a_body
    else
      oac = JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(a_body),
      JRubyXML.stream_from_file(File.join(Rails.root, transform)))  
    end
    oacxml = REXML::Document.new(oac).root
    
    agents = []
    to_update = []
    to_insert = []
    uris = []
    REXML::XPath.each(oacxml,'//oa:Annotation',{"oa" => NS_OAC}) { | a_annot |
      annotation = get_annotation(a_annot.attributes['rdf:about'])
      agents.concat(OacHelper::get_software_agents(a_annot))
      if (annotation)
        if (can_update?(annotation,a_annot))
          to_update << a_annot
        else
          Raise "Invalid agent for annotation" 
        end
      elsif (a_query)
        # if we had a uri supplied in the query and couldn't find it, raise an error
        Raise "Annotation #{a_query} not found for updating"
      else  
        to_insert << a_annot
      end
    }
    errors = []
    to_update.each do |a_annot|
      begin
        uri = a_annot.attributes['rdf:about']
        targets = OacHelper::get_targets(a_annot)
        bodies = OacHelper::get_bodies(a_annot)
        motivation = OacHelper::get_motivation(a_annot)
        swagents = OacHelper::get_software_agents(a_annot)
        update_annotation(uri,targets,bodies,motivation,make_creator_uri(),swagents,a_comment)
        uris << a_annot.attributes['rdf:about']
      rescue Exception => a_e
        Rails.logger.error(a_e)
        Rails.logger.error(a_e.backtrace)
        errors << a_annot
      end 
    end
    to_insert.each do | a_annot|
      begin
        uri = a_annot.attributes['rdf:about']
        targets = OacHelper::get_targets(a_annot)
        bodies = OacHelper::get_bodies(a_annot)
        motivation = OacHelper::get_motivation(a_annot)
        swagents = OacHelper::get_software_agents(a_annot)
        add_annotation(uri,targets,bodies,motivation,make_creator_uri(),swagents[0],a_comment)
        uris << a_annot.attributes['rdf:about']
      rescue Exception => a_e
        Rails.logger.error("Unable to insert annotation",a_e)
        errors << a_e
      end
    end
    agents = agents.uniq
    # if we were passed an entire document, then loop through the agents and get 
    # any previously saved annotations for that agent which aren't there anymore
    # HACK until we support api delete
    unless (a_query)
     get_annotations().each do | a_annot |
        annot_agents = OacHelper::get_software_agents(a_annot)
        annot_uri = a_annot.attributes['@rdf:about']
        # if all agents metch and the annotation doesn't exist in the update set, delete it
        if ( (agents & annot_agents).size == agents.size && ! uris.include?(annot_uri))
          begin 
            delete_annotation(annot_uri,a_comment)
          rescue
            errors << "Unable to delete #{annot_uri}"
          end
        end
      end      
    end
    if(errors.size > 0)
      raise "Errors during update: #{errors.join(",")}"
    end
    return "<success updated=\"#{to_update.size}\" inserted=\"#{to_insert.size}\"/>"
  end
  
  # get descriptive info 
  def api_info(urls)
    # TODO these really should come from an external config file
    motivations = [];
    motivations << { :label => 'Has Translation', :value => 'oa:linking_translation'}
    motivations << { :label => 'Has Link', :value => 'oa:linking'}
    motivations << { :label => 'Has Identity', :value => 'oa:identifying'}
    motivations << { :label => 'Has Classification', :value => 'oa:classifying'}
    motivations << { :label => 'Has Comment', :value => 'oa:commenting'}
    motivations << { :label => 'Has Fragment', :value => 'http://erlangen-crm.org/efrbroo/R15_has_fragment'}
    motivations << { :label => 'Is Fragment Of', :value => 'http://erlangen-crm.org/efrbroo/R15i_is_fragment_of'}
    motivations << { :label => 'Is Longer Version Of', :value => 'http://purl.org/saws/ontology#isLongerVersionOf'}
    motivations << { :label => 'Is Shorter Version Of', :value => 'http://purl.org/saws/ontology#isShorterVersionOf'}
    motivations << { :label => 'Is Variant Of', :value => 'http://purl.org/saws/ontology#isVariantOf'}
    motivations << { :label => 'Is Verbatim Of', :value => 'http://purl.org/saws/ontology#isVerbatimOf'}
    
    tokenizer = {}
    Tools::Manager.tool_config('cts_tokenizer',false).keys.each do |name|
      tokenizer[name] =  Tools::Manager.link_to('cts_tokenizer',name,:tokenize)[:href]
    end
      
    config = 
      { :tokenizer => tokenizer,
        :motivations => motivations,
        :passage_xslt => "#{urls['parent']}/annotate_xslt",
        :cts_services => { 'repos' => "#{urls['root']}cts/getrepos/#{self.parentIdentifier.id}",
                           'capabilities' => "#{urls['root']}cts/getcapabilities/",
                           'passage' => "#{urls['root']}cts/getpassage/"
                         },
        :target_links => {
          :commentary => [],
          'Toponym Annotations' => [],
          'Treebank Annotations' => []
        }
       }
    config[:target_links][:commentary] << {:text => 'Create Commentary', :href => "#{urls['root']}commentary_cite_identifiers/create_from_annotation?publication_id=#{self.publication.id}", :target_param => 'init_value[]'}
    # temporary solution to selectively enable the toponym editor for testing
    # see https://github.com/PerseusDL/perseids_docs/issues/141
    has_toponym_hook = REXML::XPath.match(self.rdf.root,"//perseids:PerseidsTool[@rdf:resource='toponym_editor']",{'perseids' => "http://data.perseus.org/ns/perseids"}).size > 0
    
    if (Tools::Manager.tool_config(:toponym_editor) && has_toponym_hook)
      explink = Tools::Manager.link_to('toponym_editor',:recogito,:export)
      implink = Tools::Manager.link_to('toponym_editor',:recogito,:import) 
      config[:target_links]['Toponym Annotations'] << explink
      config[:target_links]['Toponym Annotations'] << {:text => implink[:text], :href => impliknk[:href], :passthrough => "#{urls['root']}/dmm_api/item/OAC/#{self.id}/partial"}  
    end
    tblink = Tools::Manager.link_to('treebank_editor','arethusa',:create,[])
    config[:target_links]['Treebank Annotations'] << {:text => tblink[:text], :href => CGI.escape(tblink[:href]), :target_param => 'text_uri'}        
    return config.to_json                  
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
      self.publication.status == 'finalizing'
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
