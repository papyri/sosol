class CTSIdentifier < Identifier  
  # This is a superclass for objects using CTS Identifiers, including
  # shared constants and methods. No instances of CTSIdentifier should be
  # created. 
  FRIENDLY_NAME = "Text"
  
  IDENTIFIER_PREFIX = 'urn:cts:' 
  IDENTIFIER_NAMESPACE = ''
  TEMPORARY_COLLECTION = 'perseids'
  TEMPORARY_TITLE = 'New Transcription'
  NS_TEI = "http://www.tei-c.org/ns/1.0"

  # responds to an interface request to retitle the file
  # by updating the label for it in its related text inventory
  def update_title new_title,lang='eng'
    self.related_inventory.update_version_label(self.urn_attribute, title, lang)
  end
  
  def titleize
    begin
      # if we don't have a publication associated with identifier yet, we're most likely
      # looking for the title for the parent 'publication' which probably should be the work title
      # and not the version-specific label
      if nil == self.publication
        title = CTS::CTSLib.workTitleForUrn(self.inventory,self.urn_attribute)
      else
        title = CTS::CTSLib.versionTitleForUrn(self.inventory,self.urn_attribute)
      end
    rescue Exception => e
      Rails.logger.error("Error retrieving title from #{self.inventory} at #{self.urn_attribute}: #{e.class.to_s}, #{e.to_s}")
    end
    if (title.nil? || title == '')
      title = self.urn_attribute
    end
  
    return title
  end

  def self.new_from_template(publication,inventory,urn,pubtype,lang)
    temp_id = self.new(:name => self.next_temporary_identifier(inventory,urn,pubtype,lang))
    temp_id.publication = publication 
    temp_id.save!
    initial_content = temp_id.file_template
    temp_id.set_content(initial_content, :comment => 'Created from SoSOL template', :actor => (publication.owner.class == User) ? publication.owner.jgit_actor : publication.creator.jgit_actor)
    return temp_id
  end
  
  def self.new_from_supplied(publication,inventory,urn,pubtype,lang,initial_content)
    # TODO - we shouldn't really supply pubtype and lang in param - instead parse it from the content
    temp_id = self.new(:name => self.next_temporary_identifier(inventory,urn,pubtype,lang))
    temp_id.publication = publication 
    temp_id.save!
    ## replace work urn with version 
    initial_content = initial_content.gsub!(/#{urn}/,temp_id.urn_attribute)
    temp_id.set_content(initial_content, :comment => 'Created from Supplied content', :actor => (publication.owner.class == User) ? publication.owner.jgit_actor : publication.creator.jgit_actor)
    return temp_id
  end
  
  def self.new_from_inventory(publication,inventory,urn,pubtype)
    document_path = inventory + "/" + CTS::CTSLib.pathForUrn(urn,pubtype)
    temp_id = self.new(:name => document_path)
    # make sure we have a path on master before forking it for this publication 
    if (publication.repository.get_file_from_branch(temp_id.to_path, 'master').blank?)
      #raise error
      raise temp_id.to_path + " not found on master"
    end
    # make sure we're not already editing this
    # TODO this is not correct - it needs to look only at those owned by the user
    # this looks up the master publications
    #exists = self.find_by_name(document_path)
    #if (exists.nil?)
      temp_id.publication = publication 
      temp_id.save!
      return temp_id
    #else
    #  raise "#{temp_id.name} is already in your edit list."
    #end
  end
  
  def self.inventories_hash
    return CTS::CTSLib.getInventoriesHash()
  end

  def self.next_temporary_identifier(collection,template,pubtype,lang)
    urnObj = CTS::CTSLib.urnObj(template)
    year = Time.now.year
    # we want to take the text group and work from the template urn and create our own edition urn
    # TODO - need to handle differing namespaces on tg and work
    # TODO - use exemplar for version
    editionPart = "#{self::TEMPORARY_COLLECTION}-#{lang}-#{year}-"
    newUrn = "urn:cts:" + urnObj.getTextGroup(true) + "." + urnObj.getWork(false) + "." + editionPart
    # NOTE if there is no edition component, this ends up with a tailing "/"
    # somewhat by accident
    document_path = collection + "/" + CTS::CTSLib.pathForUrn(newUrn,pubtype)
    string_length = document_path.sub(/\d+$/,'').length
    latest = self.find(:all,
                       :conditions => ["name like ?", "#{document_path}%"],
                       :order => "CAST(SUBSTR(name, #{string_length+1}) AS SIGNED) DESC",
                       :limit => 1)
    if latest.first.nil?
      # no constructed id's for this year/class
      document_number = 1
    else
      document_number = latest.first.to_components.last.split(/[\-;]/).last.to_i + 1
    end
    # TODO add exemplar (version) component
    return "#{document_path}#{document_number.to_s}"
  end
  
  def self.collection_names
    unless defined? @collection_names
      @collection_names = self.identifier_hash.keys
    end
    return @collection_names
  end
  
  def self.collection_names_hash
    self.collection_names
    
    unless defined? @collection_names_hash
      @collection_names_hash = {TEMPORARY_COLLECTION => TEMPORARY_COLLECTION}
      @collection_names.each do |collection_name|
        human_name = collection_name.tr('_',' ')
        @collection_names_hash[collection_name] = human_name
      end
    end
    
    return @collection_names_hash
  end
  
  def lang
    # we want to cache this call because (1) it's not likely to change often 
    # and (2) as we may call it in a request that subsequently retrieves the
    # document for display or editing, it causes a redundant fetch from git
    # which is especially costly on large files
    # caching with the publication cache_key ensures that it will be 
    # re-fetched whenever the document changes
    Rails.cache.fetch("#{self.publication.cache_key}/#{self.id}/lang") do
      REXML::XPath.first(REXML::Document.new(self.xml_content),
        "/TEI/text/@xml:lang").to_s
    end
  end
  
  def reprinted_in
    # checking for reprints is not part of the CTS model
    nil
  end
  
  def is_reprinted?
    return reprinted_in.nil? ? false : true
  end
  
  def urn_attribute
     return IDENTIFIER_PREFIX + self.to_urn_components.join(":")
  end
  
  def work_urn
    urn_obj = CTS::CTSLib.urnObj(self.urn_attribute)
    work_urn = IDENTIFIER_PREFIX + urn_obj.getTextGroup() + '.' + urn_obj.getWork(false)
    return work_urn
  end
  
  def id_attribute
     # TODO figure out best way to handle urn as id attribute (: not allowed)
     return (IDENTIFIER_PREFIX + self.to_urn_components.join("_")).gsub!(/:/,'_')
  end
  
  def n_attribute
    return id_attribute
  end
  
  def xml_title_text
    # TODO lookup title
    self.urn_attribute
  end
  
  def inventory
    return self.to_components[0]
  end
  
  # return an inventory object for related text items
  def related_text_inventory
    
    # this is a somewhat ridiculous structure
    # for backwards-compability with cts_proxy_controller.getcapabilities
    # it mimics the one created by calling inventory_to_json.xsl
    # on a TextInventory
    inv = Hash.new

    related = self.publication.identifiers.select{|i| 
      ( (i.id != self.id) && (i.class != CitationCTSIdentifier) && i.respond_to?('related_text'))}

    # add self on for a full inventory
    related << self

    if (related.size > 0)
      self_urn = CTS::CTSLib.urnObj(self.urn_attribute)
      self_tg = self_urn.getTextGroup(true)
      self_work = self_urn.getWork(false) 
      inv[self.publication.id.to_s] = 
        { 'label' => self_tg, 
          'urn' => self.publication.id.to_s,
          'works' => {
            self_work =>
            {  'label' => self_work,
               'urn' => self_work,
               'editions' => {},
               'translations' => {}
            }
          }
        }
      related.each do |r|
        r_urn = CTS::CTSLib.urnObj(r.urn_attribute)
        r_ver = r_urn.getVersion(false)
        r_pubtype = r.class == EpiTransCTSIdentifier ? 'translations' : 'editions'
        inv[self.publication.id.to_s]['works'][self_work][r_pubtype][r_ver] = 
          { 'label' => r.title.gsub(/'/, "&apos;"), 
             'urn' => r.urn_attribute, 
             'lang' => r.lang,
             'item_type' => r.class.to_s,
             'item_id' => r.id.to_s,
             'cites' => r.related_inventory.parse_inventory(r.urn_attribute)['citations']
          }  
      end
    end
    return inv    
  end
  
  def has_related_citations
      cites = self.publication.identifiers.select{|i| (i.class == CitationCTSIdentifier)}
      return cites.size() > 0
  end
  
  # Checks to see if we can retrieve any valid citations from this text
  def has_valid_reffs?
    # we want to cache this call because (1) it's not likely to change often 
    # and (2) as we may call it in a request that subsequently retrieves the
    # document for display or editing, it causes a redundant fetch from git
    # which is especially costly on large files
    # caching with the publication cache_key ensures that it will be 
    # re-fetched whenever the document changes
    Rails.cache.fetch("#{self.publication.cache_key}/#{self.id}/validreffs") do
      uuid = self.publication.id.to_s + self.urn_attribute.gsub(':','_')
      if self.related_inventory.nil?
        return false
      end
      refs = CTS::CTSLib.getValidReffFromRepo(uuid,self.related_inventory.xml_content, self.xml_content, self.urn_attribute,1)
      return ! refs.nil? && refs != ''
    end
  end

  # now that we cache data, we need to allow for it to be explicitly cleared as
  # well, although if we used a external cache like memcached it could be handled
  # there
  def clear_cache
    Rails.cache.delete("#{self.publication.cache_key}/#{self.id}/validreffs")
  end

  def related_inventory 
    self.publication.identifiers.select{|i| (i.class == CTSInventoryIdentifier)}.last
  end
  
  def to_urn_components
    temp_components = self.to_components
    # should give us, e.g.
    # [0] collection = e.g. perseus
    # [1] namespace - e.g. greekLang
    # [2] work - e.g. tlg0012.tlg001 
    # [3] edition or translation
    # [4] perseus-grc1 - edition + examplar
    # [5] 1.1 - passage
    urn_components = []
    urn_components << temp_components[1]
    urn_components << [temp_components[2],temp_components[4]].join(".")
    unless temp_components[5].nil? 
      urn_components << temp_components[5] 
    end
    return urn_components
  end
  
  def to_path
    path_components = [ self.class::PATH_PREFIX ]
    temp_components = self.to_components
     # should give us, e.g.
    # [0] collection = e.g. perseus
    # [1] namespace - e.g. greekLang
    # [2] work - e.g. tlg0012.tlg001 
    # [3] edition or translation
    # [4] perseus-grc1 - edition + examplar
    # [5] 1.1 - passage
    cts_inv = temp_components[0]
    cts_ns = temp_components[1]
    cts_urn = temp_components[2] + "." + temp_components[4]
    cts_passage = temp_components[5]
    
    cts_textgroup,cts_work,cts_edition,cts_exemplar, =
      cts_urn.split('.',4).collect {|x| x.tr(',/','-_')}
    
    # e.g. tlg0012.tlg001.perseus-grc1.1.1.xml
    cts_xml_path_components = []
    cts_xml_path_components << cts_textgroup
    unless cts_work.nil?
      cts_xml_path_components << cts_work
    end
    cts_xml_path_components << cts_edition 
    unless cts_exemplar.nil? 
      cts_xml_path_components << cts_exemplar 
    end
    unless cts_passage.nil? 
      cts_xml_path_components << cts_passage 
    end
    cts_xml_path_components << 'xml' 
    cts_xml_path = cts_xml_path_components.join('.')
    
    path_components << cts_inv
    path_components << cts_ns
    path_components << cts_textgroup
    unless cts_work.nil?
      path_components << cts_work
    end
    path_components << cts_xml_path
    
    # e.g. CTS_XML_PASSAGES/perseus/greekLang/tlg0012/tlg001/tlg0012.tlg001.perseus-grc1.1.1.xml
    return File.join(path_components)
  end
  
   ## get a link to the catalog for this identifier  
  def get_catalog_link
    #return "http://catalog.perseus.tufts.edu/perseus.org/xc/search/" + self.urn_attribute
    return ''
  end
  
  # default xslt for displaying an annotation view of a CTS passage
  def passage_annotate_xslt
    File.read(File.join(Rails.root,%w{data xslt cts cts_annotate.xsl}))
  end
  
  # default xslt for retrieving the subref of a CTS passage
  def passage_subref_xslt_file
    File.join(Rails.root,%w{data xslt cts passage_to_subref.xsl})
  end

  def self.find_matching_identifiers(match_id,match_user,match_fuzzy)
    identifiers = []
    if (match_fuzzy)
      possible_conflicts = Identifier.find_all_by_name(match_id, :include => :publication)
      possible_conflicts = self.find(:all,
                         :conditions => ["name like ?", "#{match_id}%"],
                         :order => "name DESC")
    else 
      possible_conflicts = Identifier.find_all_by_name(match_id, :include => :publication)
    end
    actual_conflicts = possible_conflicts.select {|pc| ((pc.publication) && (pc.publication.owner == match_user) && !(%w{archived finalized}.include?(pc.publication.status)))}
    identifiers += actual_conflicts
    return identifiers
  end

  def download_file_name
    urnObj = CTS::CTSLib.urnObj(self.urn_attribute)
    file = urnObj.getTextGroup(false) + "." + urnObj.getWork(false) + "." + urnObj.getVersion(false)
    begin
      passage = urnObj.getPassage(100)
      file = passage ? file + "." + passage : file 
    rescue
    end
    file = file + ".xml"
    file
  end

  # create a title for a publication of just this class identifier
  def self.create_title(identifier_str)
    identifier_str
  end

  # parse individual docs and metadata from a supplied TEI XML document
  def self.parse_docs(content)
  end  

  # try to parse an initialization value from posted data
  def self.api_parse_post_for_init(a_post)
    #default is no-op
  end

  def self.api_parse_post_for_identifier(a_post)
    xml = REXML::Document.new(a_post).root
    urn = REXML::XPath.first(xml,'/tei:TEI/tei:teiHeader/tei:fileDesc/tei:publicationStmt/tei:idno[@type="urn:cts"]',{"tei" => NS_TEI})
    text = REXML::XPath.first(xml,'/tei:TEI/tei:text/tei:body/tei:div',{"tei" => NS_TEI})
    unless urn.nil?
      urn = urn.text
    end
    unless text.nil?
      lang = text.attributes['xml:lang']    
      pubtype = text.attributes['type']
    end
    unless (urn && lang && pubtype)
      raise Exception.new("Unable to parse information for new URN identifier")
    end
    begin
      urnObj = CTS::CTSLib.urnObj(urn)
    rescue
      raise Exception.new("Invalid URN identifier #{urn}")
    end
    # we must have at least a work
    work = urnObj.getWork(false)
    if (work.nil? || work == '')
      raise Exception.new("Missing work identifier in #{urn}")
    end
    version = urnObj.getVersion(false)
    if (version)
      raise Exception.new("Creating a new version from a version URN is not yet supported")
    end
    self::next_temporary_identifier(self::TEMPORARY_COLLECTION,urn,pubtype,lang)
  end
      

  def self.api_create(a_publication,a_agent,a_body,a_comment)
    temp_id = self.new(:name => self.api_parse_post_for_identifier(a_body))
    temp_id.publication = a_publication 
    temp_id.save!
    ## replace work urn with version 
    urn = temp_id.urn_attribute
    urnObj = CTS::CTSLib.urnObj(urn)
    workUrn = "urn:cts:" + urnObj.getTextGroup(true) + "." + urnObj.getWork(false)
    # TODO we should really only do this explicitly in the idno header
    a_body.gsub!(/\b#{workUrn}\b/,temp_id.urn_attribute)
    temp_id.set_content(a_body, :comment => a_comment, :actor => (a_publication.owner.class == User) ? a_publication.owner.jgit_actor : a_publication.creator.jgit_actor)
    template_init = temp_id.add_change_desc(a_comment)
    temp_id.set_xml_content(template_init, :comment => 'Initializing Content')
    return temp_id
  end
end
