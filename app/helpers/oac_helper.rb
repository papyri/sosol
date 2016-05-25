module OacHelper
  
  NS_RDF = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  NS_RDFS = "http://www.w3.org/2000/01/rdf-schema#"
  NS_DCTERMS = "http://purl.org/dc/terms/"  
  NS_DC = "http://purl.org/dc/elements/1.1/"
  NS_FOAF = "http://xmlns.com/foaf/0.1/"  
  NS_OAC = "http://www.w3.org/ns/oa#" 
  NS_OACOLD = "http://www.openannotation.org/ns/" 
  NS_CONTENT = "http://www.w3.org/2008/content#"
  NS_PROV = "http://www.w3.org/ns/prov#"
 
  
  # get the annotation identified by requested uri from the supplied document
  def self.get_annotation(a_doc,a_uri)
    xpath = "//oa:Annotation[@rdf:about='#{a_uri}']"
    annot = REXML::XPath.first(a_doc, xpath,{"oa"=>NS_OAC})
    if (annot.nil?)
      xpath = "//oac:Annotation[@rdf:about='#{a_uri}']"
      annot = REXML::XPath.first(a_doc, xpath,{"oac"=>NS_OACOLD}) 
    end     
    return annot     
  end
  
    # get the first annotation from the supplied document
  def self.get_first_annotation(a_doc)
    xpath = "//oa:Annotation"
    annot = REXML::XPath.first(a_doc, xpath,{"oa"=>NS_OAC})
    if (annot.nil?)
      xpath = "//oac:Annotation"
      annot = REXML::XPath.first(a_doc, xpath,{"oac"=>NS_OACOLD}) 
    end     
    return annot     
  end
  
  # get all the annotations from the supplied document
  def self.get_all_annotations(a_doc)
    xpath = "//oa:Annotation"
    all = REXML::XPath.match(a_doc,xpath,{"oa"=>NS_OAC} )
    if (all.size == 0)
      xpath = "//oac:Annotation"
      all = REXML::XPath.match(a_doc,xpath,{"oac"=>NS_OACOLD})
    end       
    return all
  end
  
  def self.get_annotations_by_annotator(a_doc,a_annotator)
    xpath = "//oa:Annotation[oa:annotatedBy/foaf:Person[@rdf:about = '#{a_annotator}']]"
    return REXML::XPath.match(a_doc,xpath,{"oa"=>NS_OAC, "rdf" => NS_RDF, "foaf" => NS_FOAF} )
  end
  
  # delete the annotiation identified by the uri from the supplied document
  def self.remove_annotation(a_doc,a_uri)
    xpath = "//oa:Annotation[@rdf:about = '#{a_uri}']"
    REXML::XPath.each(a_doc,xpath,{"oa" => NS_OAC, "rdf" => NS_RDF}) { | a_el |
      a_doc.root.elements.delete a_el
    }
  end
  
  # get the target uris from the supplied annotation
  def self.get_targets(a_annotation)
    uris = []
    xpath = "oa:hasTarget/@rdf:resource"
    REXML::XPath.each(a_annotation, xpath, {"oa" => NS_OAC, "rdf" => NS_RDF}) { |tgt|
      uris << tgt.value
    }
    if (uris.size == 0)
      xpath = "oac:hasTarget/@rdf:resource"
      REXML::XPath.each(a_annotation, xpath, { "oac" => NS_OACOLD, "rdf" => NS_RDF}) { |tgt|
      uris << tgt.value
    } 
    end          
    return uris
  end
  
  # check to see if a supplied target uri is referenced in the supplied annotation
  def self.has_target?(a_annotation,a_uri)
    has_target = false;
    Rails.logger.info("looking for #{a_uri} in #{a_annotation}")
    xpath = "oa:hasTarget[@rdf:resource = '#{a_uri}']]"
    if ! REXML::XPath.first(a_annotation, xpath, {'oa'=>NS_OAC,'oac' => NS_OACOLD}).nil?
        has_target = true
    end
    return has_target
  end 
  
  # get the body uri from the supplied annotation
  def self.get_bodies(a_annotation)
    xpath = "oa:hasBody/@rdf:resource"
    uris = []
    REXML::XPath.each(a_annotation, xpath, {"oa" => NS_OAC, "rdf" => NS_RDF}) { |body|
      uris << body.value
    }     
    return uris
  end
  
  def self.get_body_text(a_annotation)
    xpath = "oa:hasBody/cnt:ContentAsText/cnt:chars"
    chars = REXML::XPath.first(a_annotation,xpath, {"oa" => NS_OAC, "cnt" => NS_CONTENT})
    if chars.nil?
      return ""
    else 
      Rails.logger.info("Found #{chars.text}")
      chars.text
    end
  end
  
  def self.get_body_xml(a_annotation)
    xpath = "oac:hasBody[rdf:type[@rdf:resource='cnt:ContentAsXML']]/cnt:rest"
    cnt = REXML::XPath.first(a_annotation,xpath, {"oac" => NS_OACOLD, "cnt" => NS_CONTENT})
    if cnt.nil?
      return ""
    else 
      REXML::XPath.first(cnt)
    end
  end
  
  def self.get_body_content(a_annotation)
    xpath = "oa:hasBody/cnt:ContentAsText"
    REXML::XPath.first(a_annotation,xpath, {"oa" => NS_OAC, "cnt" => NS_CONTENT})
  end
  
  
  def self.get_body_language(a_annotation)
    xpath = "oa:hasBody/cnt:ContentAsText/dc:language"
    language = REXML::XPath.first(a_annotation,xpath, {"oa" => NS_OAC, "cnt" => NS_CONTENT})
    unless language.nil?
      return language.text
    else
      # TODO should we throw an error instead?
      return "eng"
    end
  end
  
  # get the creator uri from the supplied annotation
  def self.get_creator(a_annotation)
    xpath = "dcterms:creator/foaf:Agent/@rdf:about"
    creator = ""
    REXML::XPath.each(a_annotation, xpath, {"dcterms"=> NS_DCTERMS, "foaf" => NS_FOAF, "rdf" => NS_RDF}) { |uri|
      creator = uri.value
    }          
    return creator
  end
  
  # get the agent(s) from the supplied annotation
  def self.get_software_agents(a_annotation)
    xpath = "oa:serializedBy/prov:SoftwareAgent"
    agents = []
    REXML::XPath.each(a_annotation, xpath, {"oa" => NS_OAC, "prov" => NS_PROV, "rdf" => NS_RDF, "rdfs" => NS_RDFS}) { |agent|
      if agent.attributes['rdf:about']
        agents << agent.attributes['rdf:about']
      else
        agents << REXML::XPath.first(agent,'rdfs:label',{"rdfs" => NS_RDFS}).text
      end
    }          
    return agents
  end
    
  
  # get the created date from the supplied annotation
  def self.get_created(a_annotation)
    xpath = "dcterms:created"
    created = ""
    REXML::XPath.each(a_annotation, xpath, {"dcterms"=> NS_DCTERMS}) { |date|
      created = date.text
    }          
    return created
  end
  
  # get the oac:annotatedAt element
  def self.get_annotated_at(a_annotation)
    xpath = "oa:annotatedAt"
    at = REXML::XPath.first(a_annotation, xpath, {"oa"=> NS_OAC}).text 
    return at || ""
  end
  
  # get the motivation from the supplied annotation
  def self.get_motivation(a_annotation)    
    REXML::XPath.first(a_annotation, "oa:motivatedBy", {"oa"=> NS_OAC, "rdf" => NS_RDF}).attributes['rdf:resource']
  end
  
  # get the title from the supplied annotation
  def self.get_title(a_annotation)
    xpath = "dcterms:title"
    title = ""
    REXML::XPath.each(a_annotation, xpath, {"dcterms"=> NS_DCTERMS}) { |el|
      title = el.text
    }          
    return title
  end
  
  # get the list of annotators in the supplied annotation
  def self.get_annotators(a_annotation)
    xpath = "oa:annotatedBy/foaf:Person/@rdf:about"
    uris = []
    REXML::XPath.each(a_annotation, xpath, {"oa"=> NS_OAC, "foaf" => NS_FOAF, "rdf" => NS_RDF}) { |uri|
      uris << uri.value
    }          
    return uris
  end
  
  # create an oac:hasTarget element
  def self.make_target(target_uri)
    target = REXML::Element.new("hasTarget")
    target.add_namespace(NS_OAC)
    target.add_namespace("rdf",NS_RDF)
    target.add_attribute('rdf:resource',target_uri)
    return target
  end
  
  # create an oac:hasBody element
  def self.make_body(body_uri)
    body = REXML::Element.new("hasBody")
    body.add_namespace(NS_OAC)
    body.add_namespace("rdf",NS_RDF)
    body.add_attribute('rdf:resource',body_uri)
    return body
  end
  
  # make a creator uri from the owner of the publication 
  def self.make_creator_uri(a_user_id)
    ActionController::Integration::Session.new.url_for(:host => Sosol::Application.config.user_namespace, :controller => 'user', :action => 'show', :user_name => a_user_id, :only_path => false)
  end
  
  # create a dcterms:creator element
  def self.make_creator(creator_uri)
    creator = REXML::Element.new("creator")
    creator.add_namespace(NS_DCTERMS)
    agent = REXML::Element.new("Agent")
    agent.add_namespace(NS_FOAF)
    agent.add_namespace("rdf",NS_RDF)
    agent.add_attribute('rdf:about',creator_uri)
    creator.add_element(agent)
    return creator  
  end
  
  # create a prov:SoftwareAgent element
  def self.make_software_agent(a_agent)
    serialized = REXML::Element.new("serializedBy")
    serialized.add_namespace(NS_OAC)
    agent = REXML::Element.new("SoftwareAgent")
    agent.add_namespace(NS_PROV)
    # test if the agent is a uri
    begin
      URI.parse(a_agent)
      agent.add_attribute('rdf:about',a_agent)
    rescue
      # if not a uri, then just add it as a label
      agent.add_element(make_label('eng',a_agent))
    end
    serialized.add_element agent
    return serialized
  end
  
  def self.make_annotator(a_uri)
    annotator = REXML::Element.new("annotatedBy")
    annotator.add_namespace(NS_OAC)
    person = REXML::Element.new("Person")
    person.add_namespace(NS_FOAF)
    person.add_namespace("rdf",NS_RDF)
    person.add_attribute('rdf:about',a_uri)
    annotator.add_element(person)
    return annotator
  end
  
  # create a dcterms:created element
  def self.make_created()
    now = Time.new
    created = REXML::Element.new("created")
    created.add_namespace(NS_DCTERMS)
    created.add_text(now.inspect)
    return created
  end
  
  # create an oac:annotatedAt element
  def self.make_annotated_at()
    now = Time.new
    at = REXML::Element.new("annotatedAt")
    at.add_namespace(NS_OAC)
    at.add_text(now.iso8601)
    return at
  end
  
  # create a dcterms:title element
  def self.make_title(title_text)
    title = REXML::Element.new("title")
    title.add_namespace(NS_DCTERMS)
    title.add_text(title_text)
    return title
  end
  
  # create an rdfs:label element
  def self.make_label(label_lang,label_text)
    label = REXML::Element.new("label")
    label.add_namespace(NS_RDFS)
    label.add_attribute('xml:lang',label_lang)
    label.add_text(label_text)
    return label
  end
  
  # create an oac:motivatedBy element
  def self.make_motivation(motivation_uri)
    elem = REXML::Element.new("motivatedBy")
    elem.add_namespace(NS_OAC)
    elem.add_namespace("rdf",NS_RDF)
    elem.add_attribute('rdf:resource',motivation_uri)
    return elem
  end
  
  # create an inline body element
  def self.make_body_text(a_body_uri,a_language,a_text)
    elem = REXML::Element.new("hasBody")
    elem.add_namespace(NS_OAC)
    
    content = REXML::Element.new("ContentAsText")
    content.add_namespace(NS_CONTENT)
    content.add_namespace("rdf",NS_RDF)
    content.add_attribute('rdf:about',a_body_uri)
    
    type = REXML::Element.new("type")
    type.add_namespace(NS_RDF)
    type.add_namespace("rdf",NS_RDF)
    type.add_attribute('rdf:resource','http://purl.org/dc/dcmitype/Text')
    content.add_element(type)
    
    format = REXML::Element.new("format")
    format.add_namespace(NS_DC)
    format.add_text("text/plain")
    content.add_element(format)
    
    if (! a_language.nil?)
      language = REXML::Element.new("language")
      language.add_namespace(NS_DC)
      language.add_text(a_language)
      content.add_element(language)
   end
  
    if (!a_text.nil?)
      chars = REXML::Element.new("chars")
      chars.add_namespace(NS_CONTENT)
      chars.add_text(a_text)
      content.add_element(chars)
    end
    
    elem.add_element(content)
    return elem
  end
  
  def self.update_body_text(a_annotation,a_language,a_text)
    cnt = get_body_content(a_annotation)
    language_xpath = "dc:language"
    lang = REXML::XPath.first(cnt, language_xpath,{"dc" => NS_DC}) 
    if (lang.nil?)
      language = REXML::Element.new("language")
      language.add_namespace(NS_DC)
      language.add_text(a_language)
      cnt.add_element(language)
    else
      lang.text = a_language
    end
    chars_xpath = "cnt:chars"
    chars = REXML::XPath.first(cnt,chars_xpath,{"cnt" => NS_CONTENT})
    if (chars.nil?)
      chars = REXML::Element.new("chars")
      chars.add_namespace(NS_CONTENT)
      chars.add_text(a_text)
      cnt.add_element(chars)
    else
      chars.text = a_text
    end
  end
  
  # make an oac:Annotation element
  def self.make_annotation(annot_uri,target_uris,body_uris,motivation,creator_uri,agent)
    annot = REXML::Element.new("Annotation")
    annot.add_namespace(NS_OAC)
    annot.add_namespace("rdf",NS_RDF)
    annot.add_attribute('rdf:about',annot_uri)
    target_uris.each do |uri|
      annot.add_element(make_target(uri))
    end
    body_uris.each do |uri|
      annot.add_element(make_body(uri))
    end
    annot.add_element(make_motivation(motivation))
    annot.add_element(make_annotator(creator_uri))
    annot.add_element(make_annotated_at())
    unless (agent.nil?)
      annot.add_element(make_software_agent(agent))
    end
    return annot
  end    
  
  # make an oac:Annotation element from supplied attributes
  def self.make_text_annotation(a_atts)
    # TODO raise error unless we have  target, body, annotator and motivation
    annot = REXML::Element.new("Annotation")
    annot.add_namespace(NS_OAC)
    annot.add_namespace("rdf",NS_RDF)
    annot.add_attribute('rdf:about',a_atts['uri'])
    a_atts['target_uris'].each do |uri|
      annot.add_element(make_target(uri))
    end
    annot.add_element(make_body_text(a_atts['body_uri'],a_atts['body_language'],a_atts['body_text']))
    if (! a_atts['labels'].nil?)
      a_atts['labels'].each do |label|
        annot.add_element(make_label(label['language'],label['text']))
      end
    end
    annot.add_element(make_annotator(a_atts['annotator_uri']))
    annot.add_element(make_motivation(a_atts['motivation']))
    annot.add_element(make_annotated_at)
    return annot
  end

  # update the targets of the supplied annotation
  def self.update_targets(a_annotation,a_targets)
    xpath = "oa:hasTarget"
    # delete any the existing targetts
    REXML::XPath.each(a_annotation, xpath, {"oa" => NS_OAC, "rdf" => NS_RDF}) { |target|
      a_annotation.root.elements.delete target
    }
    # add new targets
    a_atts['target_uris'].each do |uri|
      a_annotation.add_element(make_target(uri))
    end
    return a_annotation
  end
  
  def self.add_annotator(a_annotation,a_uri)
     xpath = "oa:Annotation"
      REXML::XPath.each(a_annotation, xpath,{"rdf" => NS_RDF, "oa" => NS_OAC}) { |el|
        # only add the annotator if not already there
        if REXML::XPath.match(el,"oa:annotatedBy/foaf:Person[@rdf:about =  '#{a_uri}']").length == 0
           el.add_element(make_annotator(a_uri))
        end
      }
      return a_annotation   
  end
  
  # Updates the annotation uri and body uri for inline content
  def self.update_annotation_uris(a_annotation,a_annot_uri,a_body_uri)
    a_annotation.delete_attribute('rdf:about')
    a_annotation.add_attribute('rdf:about',a_annot_uri)    
    unless (a_body_uri.nil?)
      xpath = "oa:hasBody/cnt:ContentAsText"
      REXML::XPath.each(a_annotation, xpath, {"oa" => NS_OAC, "rdf" => NS_RDF, "cnt" => NS_CONTENT}) { |body|
        body.delete_attribute('rdf:about')
        body.add_attribute('rdf:about',a_body_uri)
      }    
    end

  end

  
  # Check for annotations with an external source in an oa annotation document
  # (as specified by the serializing software agent)
  # - *Params*    :
  # - +doc+ -> the annotation document
  # - *Returns*   :
  #   - true if any are externally sourced, false if not
  # TODO at some point it might be useful to return the list of external sourced annotations
  # but as this code would perform very badly for large annotation sets, leaving that until we have an
  # external collections solution for these
  def self.has_externally_sourced_annotations?(a_doc)
    has_external = false
    xpath = "oa:serializedBy/prov:SoftwareAgent"
    REXML::XPath.each(a_doc,"//oa:Annotation/oa:serializedBy/prov:SoftwareAgent",{"oa" => NS_OAC, "prov" => NS_PROV}) do |a| 
      if AgentHelper::agent_of(a.attributes['rdf:about']) 
        has_external = true 
        break;
       end
    end
    return has_external
  end

end
