class OACIdentifier < Identifier  
  # This is a base class for OAC Annotations.
  
  PATH_PREFIX = 'XML_OAC'
  IDENTIFIER_NAMESPACE = 'oac'
  FRIENDLY_NAME = 'Annotations'
  TEMPORARY_COLLECTION = 'TempAnnotations'
  TEMPORARY_TITLE = 'Annotations'
  XML_VALIDATOR = JRubyXML::RDFValidator

  NS_RDF = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  NS_DCTERMS = "http://purl.org/dc/terms/"  
  NS_FOAF = "http://xmlns.com/foaf/0.1/"  
  NS_OAC = "http://www.openannotation.org/ns/"  
  
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
    xpath = "/rdf:RDF/oac:Annotation"
    hasany = false
    begin
      if ! REXML::XPath.first(self.rdf, xpath).nil?
        hasany = true
      end
    rescue StandardError => e
      ## TODO?
      Rails.logger.error("Error checking for annotation #{e.to_s}")
    end      
    return hasany
  end
  
  # get the requested annotation by uri from the oac.xml 
  def get_annotation(a_uri)
    xpath = "/rdf:RDF/oac:Annotation[@rdf:about='#{a_uri}']"
    REXML::XPath.first(self.rdf, xpath)          
  end
  
  # get the target uris from the supplied annotation
  def get_targets(a_annotation)
    xpath = "oac:hasTarget/@rdf:resource"
    uris = []
    REXML::XPath.each(a_annotation, xpath) { |tgt|
      uris << tgt.value
    }          
    return uris
  end
  
  # get the body uri from the supplied annotation
  def get_body(a_annotation)
    xpath = "oac:hasBody/@rdf:resource"
    uri = nil
    REXML::XPath.each(a_annotation, xpath) { |body|
      uri = body.value
    }          
    return uri
  end
  
  # get the creator uri from the supplied annotation
  def get_creator(a_annotation)
    xpath = "dcterms:creator/foaf:Agent/@rdf:about"
    creator = ""
    REXML::XPath.each(a_annotation, xpath) { |uri|
      creator = uri.value
    }          
    return creator
  end
  
  # get the created date from the supplied annotation
  def get_created(a_annotation)
    xpath = "dcterms:created"
    created = ""
    REXML::XPath.each(a_annotation, xpath) { |date|
      created = date.text
    }          
    return created
  end
  
  # get the title from the supplied annotation
  def get_title(a_annotation)
    xpath = "dcterms:title"
    title = ""
    REXML::XPath.each(a_annotation, xpath) { |el|
      title = el.text
    }          
    return title
  end
  
  # look for Annotations whose target resource matches the targetUriMatch string
  # targeUriMatch is expected to be a properly quoted regex string
  def matching_targets(targetUriMatch,creatorUri)
    matches = []
    xpath = "/rdf:RDF/oac:Annotation[dcterms:creator/foaf:Agent[@rdf:about =  '#{creatorUri}']]"
    REXML::XPath.each(self.rdf, xpath) { |el| 
      annot_id = el.attributes['rdf:about']
      REXML::XPath.each(el, "oac:hasTarget/@rdf:resource" ) { |tgt|  
        Rails.logger.info("Comparing #{tgt} to #{targetUriMatch}")
        if tgt.value =~ /#{targetUriMatch}/ 
          Rails.logger.info("Matched")
          match = Hash.new
          match['id'] = annot_id
          match['target'] = tgt.value
          matches << match   
        end
      }
    }
    return matches
  end
  
  # check to see if the supplied target is already used for any of the annotations owned by the requesting user
  def has_target?(targetUri,creatorUri)
    has_target = false
    if (self.has_anyannotation?)
      # this is annoying .. REXML doesn't seem to support multiple predicates combined with and?
      # /rdf:RDF/oac:Annotation[oac:Target] succeeds
      # /rdf:RDF/oac:Annotation[dcterms:creator] succeeds
      # but /rdf:RDF/oac:Annotation[oac:Target and dcterms:creator] fails
      xpath = "/rdf:RDF/oac:Annotation[oac:hasTarget[@rdf:resource = '#{targetUri}']]"
      REXML::XPath.each(self.rdf, xpath) { |el|
        if el.get_elements("dcterms:creator/foaf:Agent[@rdf:about =  '#{creatorUri}']").length == 1
           has_target = true
        end
      }   
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
  def update_annotation(annot_uri,target_uris,body_uri,title,creator_uri,comment)
    xpath = "/rdf:RDF/oac:Annotation[@rdf:about = '#{annot_uri}']"
    annot = REXML::XPath.first(self.rdf, xpath) 
    if (annot.nil?)
      Rails.logger.info("Not found #{annot_uri}")
      Rails.logger.info(toXmlString self.rdf)
      raise "Unable to find #{annot_uri}."
    end
    annot.elements.delete_all '*'
    target_uris.each do |uri|
      annot.add_element(self.make_target(uri))
    end
    annot.add_element(self.make_body(body_uri))
    annot.add_element(self.make_title(title))
    annot.add_element(self.make_creator(creator_uri))
    annot.add_element(self.make_created)
    # calling toXmlString to ensure consistent formatting throughout lifecycle of the file
    oacRdf = toXmlString self.rdf
    self.set_xml_content(oacRdf, :comment => comment)
  end
  
  # add a new annotation to the oac.xml file
  def add_annotation(annot_uri,target_uris,body_uri,title,creator_uri,comment)
    xpath = "/rdf:RDF/oac:Annotation[@rdf:about = '#{annot_uri}']"
    unless (REXML::XPath.first(self.rdf, xpath).nil?)
      raise "An annotation identified by #{annot_uri} already exists."
    end
    self.rdf.elements.delete_all xpath
    self.rdf.root.add_element(self.make_annotation(annot_uri,target_uris,body_uri,title,creator_uri))
    # calling toXmlString to ensure consistent formatting throughout lifecycle of the file
    oacRdf = toXmlString self.rdf
    self.set_xml_content(oacRdf, :comment => comment)
  end
  
  # delete an existing annotation from the oac.xml file
  def delete_annotation(annot_uri,comment)
    xpath = "/rdf:RDF/oac:Annotation[@rdf:about = '#{annot_uri}']"
    self.rdf.elements.delete_all xpath
    unless (REXML::XPath.first(self.rdf, xpath).nil?)
      raise "Unable to delete #{annot_uri}."
    end
    # calling toXmlString to ensure consistent formatting throughout lifecycle of the file
    oacRdf = toXmlString self.rdf
    self.set_xml_content(oacRdf, :comment => comment)
  end
  
  # create an oac:hasTarget element
  def make_target(target_uri)
    target = REXML::Element.new("hasTarget")
    target.add_namespace(self::class::NS_OAC)
    target.add_attribute('rdf:resource',target_uri)
    return target
  end
  
  # create an oac:hasBody element
  def make_body(body_uri)
    body = REXML::Element.new("hasBody")
    body.add_namespace(self::class::NS_OAC)
    body.add_attribute('rdf:resource',body_uri)
    return body
  end
  
  # make a creator uri from the owner of the publication 
  def make_creator_uri()
    ActionDispatch::Integration::Session.new(Sosol::Application).url_for(:host => Sosol::Application.config.site_user_namespace, :controller => 'user', :action => 'show', :user_name => self.publication.creator.id, :only_path => false)
  end
  
  # create a dcterms:creator element
  def make_creator(creator_uri)
    creator = REXML::Element.new("creator")
    creator.add_namespace(self::class::NS_DCTERMS)
    agent = REXML::Element.new("Agent")
    agent.add_namespace(self::class::NS_FOAF)
    agent.add_attribute('rdf:about',creator_uri)
    creator.add_element(agent)
    return creator  
  end
  
  # create a dcterms:created element
  def make_created()
    now = Time.new
    created = REXML::Element.new("created")
    created.add_namespace(self::class::NS_DCTERMS)
    created.add_text(now.inspect)
    return created
  end
  
  # create a dcterms:title element
  def make_title(title_text)
    title = REXML::Element.new("title")
    title.add_namespace(self::class::NS_DCTERMS)
    title.add_text(title_text)
    return title
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
    REXML::XPath.each(self.rdf, "//oac:Annotation") { |el|
      annot_id = el.attributes['rdf:about']
      num_this_creator = annot_id.split(/\//).last.to_i
      if (num_this_creator > max)
        max = num_this_creator
      end
    }
    next_num = max+1
    return "#{SITE_OAC_NAMESPACE}/#{self.publication.id}/#{self.parentIdentifier.id}/#{self.id}/#{self.publication.owner.id}/#{next_num}" 
  end

  # make an oac:Annotation element
  def make_annotation(annot_uri,target_uris,body_uri,title_text,creator_uri)
    annot = REXML::Element.new("Annotation")
    annot.add_namespace(self::class::NS_OAC)
    annot.add_attribute('rdf:about',annot_uri)
    target_uris.each do |uri|
      annot.add_element(self.make_target(uri))
    end
    annot.add_element(self.make_body(body_uri))
    annot.add_element(self.make_title(title_text))
    annot.add_element(self.make_creator(creator_uri))
    annot.add_element(self.make_created)
    return annot
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
      JRubyXML.stream_from_file(File.join(Rails.root,
        xsl ? xsl : %w{data xslt oac html_preview.xsl})),
        parameters)
  end
end
