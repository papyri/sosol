#encoding "utf-8"
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

  # Create a new OaCiteIdentifier from the template
  # - *Args* :
  #   - +a_publication+ -> parent Publication
  #   - +a_urn* -> String value of the CITE URN identifier for the parent collection
  #   - +a_init_value+ -> Optional array of String values of URIs for external sources
  #                       from which to retrieve the initial content of this document
  #                       must match a configured Agent URI
  #                       @see AgentHelper
  def self.new_from_template(a_publication,a_urn,a_init_value)
    # defer to super class handling if we don't have any class-specific
    # init content
    if a_init_value.size == 0 
      return super(a_publication,a_urn,a_init_value)
    end

    temp_id = self.new(:name => self.next_object_identifier(a_urn))
    cts_targets = []
    a_init_value.each do |a|
      if  a =~ /urn:cts/
        abbr = CTS::CTSLib.urn_abbr(a)
        cts_targets << abbr 
      end
    end
    # if we have all cts targets we use them in the title
    if (cts_targets.size == a_init_value.size) 
      temp_id.title = "On #{cts_targets.join(',')}"
    else
      temp_id.title = temp_id.name
    end
    temp_id.publication = a_publication 
    if (! temp_id.collection_exists?)
      raise "Unregistered CITE Collection for #{a_urn}"
    end
    initial_content = temp_id.file_template
    temp_id.set_content(initial_content, :comment => 'Created from SoSOL template', :actor => (a_publication.owner.class == User) ? a_publication.owner.jgit_actor : a_publication.creator.jgit_actor)
    params = {
      :e_annotatorUri => temp_id.make_annotator_uri(),
      :e_annotatorName => temp_id.publication.creator.human_name,
      :e_baseAnnotUri => Sosol::Application.config.site_cite_collection_namespace + "/" + temp_id.urn_attribute  + "/"
    }
    updated_content = AgentHelper::content_from_agent(a_init_value,:OaCiteIdentifier,params)
    temp_id.set_xml_content(updated_content, :comment => "Initializing Content from #{a_init_value}")
    temp_id.save!
    return temp_id
  end
 
  # @see Identifier.add_change_desc 
  def add_change_desc(text = "", user_info = self.publication.creator, input_content = nil, timestamp = Time.now.xmlschema)
    # TODO implement prov tracking of annotations
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
  
  # make a annotator uri from the owner of the publication 
  def make_annotator_uri()
    "#{Sosol::Application.config.site_user_namespace}#{URI.escape(self.publication.creator.name)}"
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
  
  # Test to see if any annotations have been added to the annotation RDF/XML file yet
  # - *Returns* :
  #   - True or False
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

  # Get the requested annotation by uri from the annotation RDF/XMLfile
  # - *Args* :
  #   - +a_uri+ -> String value of the annotation URI to retrieve
  # - *Returns* :
  #  the RDF/XML of the requested annotation or Nil if not found
  def get_annotation(a_uri)
   Rails.logger.info("Get Annotation #{a_uri}")
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
        Rails.logger.info("Comparing #{tgt} to #{targetUriMatch}")
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
  
  # TODO need to update the uris to reflect the new name
  def after_rename(options = {})
     raise "Rename not supported yet!"
  end


  # api_get responds to a call from the data management api controller
  # to get all or a specific annotation from the parent document
  # - *Args* :
  #   - +a_query+ -> String matching uri=<annotation_uri>
  #                  Optional. If not supplied all will be returned. 
  # - *Returns* :
  #   - the requested annotation(s) as a string or Nil if not found
  def api_get(a_query)
    # query will contain the uri of the annotation
    xmlobj = nil
    if (a_query)
      qmatch = /^uri=(.*?)$/.match(a_query)
      if (qmatch.nil?)
        raise "Invalid request - no uri specified in #{a_query}"
      else
        xmlobj = get_annotation(qmatch[1])
      end
    else
      xmlobj = self.rdf
    end
    unless xmlobj.nil?
      xmlobj = toXmlString xmlobj
    end
    return xmlobj
  end
  
  # api_append responds to a call from the data management api controller
  # to append a new annotation to the parent document
  # - *Args* :
  #   - +a_agent+ -> the software agent initiating the append request
  #   - +a_body+ -> String containing the raw body of the data to be appended
  #   - + a_comment+ -> String comment for the commit message
  # - *Returns* :
  #   - the URI of the newly appended annotation
  def api_append(a_agent,a_body,a_comment)
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
  
  # api_update responds to a call from the data management api controller
  # to update an existing annotation or annotations in the parent document
  # NB THIS CODE IS NOT CURRENTLY IN USE - IT WAS WRITTEN FOR THE RECOGITO
  # INTEGRATION, WHICH HAS BEEN REMOVED NOW. THIS SHOULD PROBABLY ALL BE
  # HANDLED BY AN LDP IMPLEMENTATION INSTEAD
  # - *Args* :
  #  - +a_query+ -> String parameter containing a querystring
  #                 specific to the identifier type. 
  #  - +a_body+ -> String containing the raw body of the data
  #  - +a_comment+ -> String comment for the commit message
  #
  def api_update(a_agent,a_query,a_body,a_comment)
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
  
  # get descriptive info for the identifier document
  # TODO all of this should be moved out of here and done elsewhere
  def api_info(urls)
    # TODO ontology definition belongs on the annotation client
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
        :cts_services => { 'repos' => "#{urls['root']}cts/getrepos/#{self.publication.id}",
                           'capabilities' => "#{urls['root']}cts/getcapabilities/",
                           'passage' => "#{urls['root']}cts/getpassage/"
                         },
        :target_links => {
          :commentary => [],
          'Treebank Annotations' => []
        }
       }
    config[:target_links][:commentary] << {:text => 'Create Commentary', :href => "#{urls['root']}commentary_cite_identifiers/create_from_annotation?publication_id=#{self.publication.id}", :target_param => 'init_value[]'}
    
    tblink = Tools::Manager.link_to('treebank_editor','arethusa',:create,[])
    config[:target_links]['Treebank Annotations'] << {:text => tblink[:text], :href => CGI.escape(tblink[:href]), :target_param => 'text_uri'}        
    return config.to_json                  
  end

 
  # Check to see if import should be allowed.
  # Currently disabled for all annotations with external sources
  def can_import?
    OacHelper::has_externally_sourced_annotations?(self.rdf)
  end

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
  
    # private method to find the next annotation uri for appending to the parent document
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
end
