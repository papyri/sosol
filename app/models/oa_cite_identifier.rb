#encoding "utf-8"
class OaCiteIdentifier < CiteIdentifier   
  include OacHelper


  FRIENDLY_NAME = "Annotation"
  PATH_PREFIX="CITE_OA_XML"
  FILE_TYPE="oac.xml"
  XML_VALIDATOR = JRubyXML::RDFValidator


  ##################################
  # Public Instance Method Overrides
  ##################################

  # @overrides Identifier.add_change_desc
  def add_change_desc(text = "", user_info = self.publication.creator, input_content = nil, timestamp = Time.now.xmlschema)
    # TODO implement prov tracking of annotations
    # this is a no-op because change desc is not added to this file
    # need to override to ensure consistent formatting of XML for all commits
    toXmlString self.rdf
  end

  # Commits identifier XML to the repository.
  # Overrides Identifier#set_content to reset memoized value set in OaaCiteidentifier#rdf.
  # - *Args*  :
  #   - +content+ -> the XML you want committed to the repository
  #   - +options+ -> hash of options to pass to repository (ex. - :comment, :actor)
  # - *Returns* :
  #   - a String of the SHA1 of the commit
  def set_content(content, options = {})
    @rdfDocX = nil
    super
  end

  # TODO need to update the uris to reflect the new name
  def after_rename(options = {})
     raise Exception.new("Rename not supported yet!")
  end

  # @overrides Identifier.fragment
  # - *Args* :
  #   - +a_query+ -> Query string in the format
  #                  uri=<annotation_uri>
  # - *Returns*:
  #   the fragment containing the requested annotation
  def fragment(a_query)
    # query will contain the uri of the annotation
    xmlobj = nil
    qmatch = /^uri=(.*?)$/.match(a_query)
    if (qmatch.nil?)
      raise Exception.new("Invalid request - no uri specified in #{a_query}")
    end
    xmlobj = get_annotation(qmatch[1])
    unless xmlobj.nil?
      xmlobj = toXmlString xmlobj
    end
    return xmlobj
  end

  # @overrides Identifier.patch_content
  # - *Args* :
  #   - +a_agent+ -> String URI identifying the agent making the patch
  #   - +a_query+ -> Query string in the format
  #                  uri=<annotation_uri>
  #   + +a_content+ -> the patch content
  #   + +a_comment+ -> a commit comment
  # - *Returns*:
  #   the fragment containing the requested annotation
  def patch_content(a_agent,a_query,a_content,a_comment)
    # append is a special case of patch
    if (a_query) == 'APPEND'
      return self.append(a_agent,a_content,a_comment)
    end
    transform = nil
    if (! a_agent.nil? && a_agent[:transformations][:OaCiteIdentifier])
      transform = a_agent[:transformations][:OaCiteIdentifier]
    end
    if (transform.nil?)
      oac = a_content
    else
      oac = JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(a_content),
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
        unless (conflicting_agents?(annotation,a_annot))
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



  ##########################
  # Private Helper Methods
  ##########################

  ##############################################
  # OaCiteIdentifier Specific Instance Methods
  ##############################################

  # Get the requested annotation by uri from the annotation RDF/XMLfile
  # - *Args* :
  #   - +a_uri+ -> String value of the annotation URI to retrieve
  # - *Returns* :
  #  the RDF/XML of the requested annotation or Nil if not found
  def get_annotation(a_uri)
   OacHelper::get_annotation(self.rdf,a_uri)
  end

  # Get all annotations from the annotation RDF/XML file
  # - *Returns* :
  # an Array of annotations. Will be empty if none present in the file.
  def get_annotations()
   OacHelper::get_all_annotations(self.rdf)         
  end
  
  # Look for Annotations whose target resource matches the targetUriMatch string
  # - *Args* :
  #   - +targetUriMatch+ a properly quoted regex string to search for as the target
  #                      of the contained annotations
  # - *Returns* :
  #   - an array of of matches - each represented as a Hash { id => uri, target => matchingtarget }
  def matching_targets(targetUriMatch)
    matches = []
    OacHelper::get_all_annotations(self.rdf).each() { |el|
      annot_id = el.attributes['rdf:about']
      OacHelper::get_targets(el).each() { |tgt|
        if tgt =~ /#{targetUriMatch}/
          match = Hash.new
          match['id'] = annot_id
          match['target'] = tgt
          matches << match   
        end
      }
    }
    return matches
  end

  # Inserts a new annotation in the parent document
  # for a specified target with an empty body
  # -*Args* :
  #   - +a_target_uri+ -> String valueof the URI for target of the annotatoin
  # -*Returns* :
  #   - String value of the URI of the newly created annotation 
  def create_annotation(a_target_uri)
    annot_uri = next_annotation_uri()
    add_annotation(annot_uri,[a_target_uri],[],nil,make_creator_uri(),nil,"Create")
    return annot_uri
  end
  
  # Delete an existing annotation from the parent document
  # - *Args* :
  #   - +annot_uri+ -> String value of the URI for the annotation to delete
  #   - +comment+ -> String comment to save with the commit message
  def delete_annotation(annot_uri,comment)
    OacHelper::remove_annotation(self.rdf,annot_uri)
    unless (OacHelper::get_annotation(self.rdf,annot_uri).nil?)
      raise "Unable to delete #{annot_uri} still have #{OacHelper::get_annotation(self.rdf,annot_uri)}."
    end
    # calling toXmlString to ensure consistent formatting throughout lifecycle of the file
    oacRdf = toXmlString self.rdf
    self.set_xml_content(oacRdf, :comment => comment)
  end

  # Check to see whether to offer an import option for this identifer
  # *Returns*: true if import is enabled, false if not
  # Currently disabled for all annotations with external sources
  def can_import?
    OacHelper::has_externally_sourced_annotations?(self.rdf)
  end

  # method to find the next annotation uri for appending to the parent document
  def next_annotation_uri()
    max = 0
    all = OacHelper::get_all_annotations(self.rdf)
    all.each { |el|
      annot_id = el.attributes['rdf:about']
      num = annot_id.split(/#/).last.to_i
      if (num > max)
        max = num
      end
    }
    next_num = max+1
    return Sosol::Application.config.site_cite_collection_namespace + "/" + self.urn_attribute  + "/#" + next_num.to_s
  end

  # @overrides Identifier.mimetype
  def mimetype
    "application/rdf+xml"
  end

  # @overrides Identifier#schema
  def schema
    'http://www.openannotation.org/spec/core/'
  end

  # @overrides Identifier#get_topics
  def get_topics
    uris = {}
    OacHelper::get_all_annotations(self.rdf).each() { |el|
      OacHelper::get_targets(el).each do |t|
        uris[t] = {}
      end
    }
    return CTS::CTSLib::validate_and_parse(uris)
  end

  #########################################
  # Private Helper Methods
  #########################################

  protected
    # private method to add a new annotation to the oac.xml file
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
  
    # private method to update a pre-existing annotation in the parent document
    def update_annotation(annot_uri,target_uris,body_uris,motivation,creator_uri,agents,comment)
      annot = OacHelper::get_annotation(self.rdf,annot_uri) 
      if (annot.nil?)
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
      # calling toXmlString to ensure consistent formatting throughout lifecycle of the file
      oacRdf = toXmlString self.rdf
      self.set_xml_content(oacRdf, :comment => comment)
    end

    #private method to test whether two annotations contain conflicting software agents
    def conflicting_agents?(a_orig,a_new)
      orig_agents = OacHelper::get_software_agents(a_orig)
      new_agents = OacHelper::get_software_agents(a_new)
    
      authorized_agent =
        # if no previous agent, then anyone is authorized to update 
        orig_agents.size == 0 ||
        # otherwise there must be at least one common agent between the original and the updated 
        (orig_agents & new_agents).size > 0
      return !authorized_agent
    end
  
    # private method to make a creator uri from the owner of the publication 
    def make_creator_uri()
      "#{Sosol::Application.config.site_user_namespace}#{URI.escape(self.publication.creator.name)}"
    end
  

    # append a new annotation at the end of the document
    def append(a_agent,a_body,a_comment)
      transform = nil
      if (! a_agent.nil? && a_agent[:transformations][:OaCiteIdentifier])
        transform = a_agent[:transformations][:OaCiteIdentifier]
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

    # return the RDF of the oac.xml as an REXML::Document
    def rdf
      @rdfDocX ||= REXML::Document.new(self.xml_content)
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
end
