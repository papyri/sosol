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
   return ''
  end
  
  def titleize
    "Annotations"
  end
  
  def add_change_desc(text = "", user_info = self.publication.creator, input_content = nil)
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
    all = get_annotations
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
  
  def can_align?(a_uri)
    if (a_uri.nil?)
      return false
    end
    annotation = self.get_annotation(a_uri)
    Rails.logger.info("Motivation=#{OacHelper::get_motivation(annotation)}")
    return OacHelper::get_motivation(annotation) == 'oa:linking_translation'
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
  
  # update a pre-existing annotation in the oac.xml file
  def update_annotation(annot_uri,target_uris,body_uri,motivation,creator_uri,agents,comment)
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
    annot.add_element(OacHelper::make_body(body_uri))
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
  def add_annotation(annot_uri,target_uris,body_uri,motivation,creator_uri,agent,comment)
    exists = OacHelper::get_annotation(self.rdf,annot_uri)
    unless (exists.nil?)
      raise "An annotation identified by #{annot_uri} already exists."
    end
    self.rdf.root.add_element(OacHelper::make_annotation(annot_uri,target_uris,body_uri,motivation,creator_uri,agent))
    # calling toXmlString to ensure consistent formatting throughout lifecycle of the file
    oacRdf = toXmlString self.rdf
    Rails.logger.info("Adding #{oacRdf}")
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
    ActionController::Integration::Session.new.url_for(:host => SITE_USER_NAMESPACE, :controller => 'user', :action => 'show', :user_name => self.publication.creator.name, :only_path => false)
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
    # same files.  For now, I'm assuming we can address this by setting the SITE_OAC_NAMESPACE to an instance
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
    return "#{SITE_OAC_NAMESPACE}/#{self.publication.id}/#{self.parentIdentifier.id}/#{self.id}/#{self.publication.owner.id}/#{next_num}" 
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
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(self.xml_content),
      JRubyXML.stream_from_file(File.join(RAILS_ROOT,
        xsl ? xsl : %w{data xslt oac html_preview.xsl})),
        parameters)
  end
  
  # api_get responds to a call from the data management api controller
  # @param [String] a_query if not nil, means use the query to 
  #                         return part of the item
  def api_get(a_query)

  end
  
  # api_update responds to a call from the data management api controller
  # @param [String] a_query  parameter containing a querystring
  #                 specific to the identifier type. We use it for TreebankIdentifiers
  #                 to identify the sentence
  # @param [String] a_body the raw body of the post data
  # @param [String] a_comment an update comment
  #
  def api_update(a_query,a_body,a_comment)
    
    if (a_query)
      # if we have a query, then update just a single annotation
      # TODO 
    else
      # otherwise, we loop through updating the annotations that already exist, appending any that don't
      # and remove any for the agent(s) which aren't there any more
      REXML::Document.new(a_body)
      agents []
      to_update = []
      to_insert = []
      uris = []
      REXML::XPath.each(a_body,'//*[oa:hasTarget]',{"oa" => NS_OA}) { | a_annot |
        annotation = get_annotation(a_annot.attributes['rdf:about'])
        agents.concat(OacHelper::get_software_agents(a_annot))
        if (annotation)
          if (can_update?(annotation,a_annot))
            to_update << a_annot
          else
            Raise "Invalid agent for annotation" 
          end
        else 
          to_insert << a_annot
        end
      }
      errors = []
      to_update.each do |a_annot|
        begin
          uri = a_annot.attributes['rdf:about']
          targets = OacHelper::get_targets(a_annot)
          body = OacHelper::get_body(a_annot)
          motivation = OacHelper::get_motivation()
          agents = OacHelper::get_software_agents()
          update_annotation(annot_uri,target_uris,body_uri,motivation,make_creator_uri(),agents,a_comment)
          uris << a_annot.attributes['rdf:about']
        rescue Exception => a_e
          Rails.logger.error("Unable to update annotation",a_e)
          errors << a_annot
        end 
      end
      to_insert.each do | a_annot|
        begin
          uri = a_annot.attributes['rdf:about']
          targets = OacHelper::get_targets(a_annot)
          body = OacHelper::get_body(a_annot)
          motivation = OacHelper::get_motivation()
          agents = OacHelper::get_software_agents()
          add_annotation(annot_uri,target_uris,body_uri,motivation,make_creator_uri(),agents,a_comment)
          uris << a_annot.attributes['rdf:about']
        rescue Exception => a_e
          Rails.logger.error("Unable to insert annotation",a_e)
          errors << a_annot
        end
      end
      agents = agents.uniq
      # now loop through the agents and get any previously saved annotations for that
      # agent which aren't there anymore -- HACK until we support api delete
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
  end
  
  # get descriptive info 
  def api_info

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
    Rails.logger.info("orig_agents = #{orig_agents.inspect} new = #{new_agents.inspect} auth=#{authorized_agent.inspect}")
    return authorized_agent && authorized_owner
      
  end
  
end
