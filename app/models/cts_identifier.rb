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


  ###################################
  # Public Class Method Overrides
  ###################################

  # @Overrides Identifier#identifier_from_content
  # to parse a work urn from supplied content
  def self.identifier_from_content(agent,content)
    xml = REXML::Document.new(content).root
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
    id = self::next_temporary_identifier(self::TEMPORARY_COLLECTION,urn,pubtype,lang)
    content.gsub(/\b#{workUrn}\b/,id.urn_attribute)
    return id,content
  end

  ###########################################
  # CTS Identifier Specific Class Methods
  ###########################################

  # Different signature for this method than in Identifier#new_from_template
  # because we need the inventory,pubtype and lang in addition to the publication
  # in order to construct a new identifier
  # This may all change when we move to CapiTaiNs and CTS5
  # - *Args* :
  #   - +publication+ -> parent publication
  #   - +inventory+-> cts inventory
  #   - +urn+ -> base work urn
  #   - +pubtype+ -> edition or translation
  #   - +lang+ -> language of the edition or translation
  # - *Returns* :
  #   - newly constructed identifier
  def self.new_from_template(publication,inventory,urn,pubtype,lang)
    temp_id = self.new(:name => self.next_temporary_identifier(inventory,urn,pubtype,lang))
    temp_id.publication = publication
    temp_id.save!
    initial_content = temp_id.file_template
    temp_id.set_content(initial_content, :comment => 'Created from SoSOL template', :actor => (publication.owner.class == User) ? publication.owner.jgit_actor : publication.creator.jgit_actor)
    return temp_id
  end

  # Instantiate an existing version of a text from the local inventory
  # This may all change when we move to CapiTaiNs and CTS5
  # - *Args* :
  #   - +publication+ -> parent publication
  #   - +inventory+-> cts inventory
  #   - +urn+ -> base work urn
  #   - +pubtype+ -> edition or translation
  # - *Returns* :
  #   - newly constructed identifier
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
  
  # Different signature for this method than in Identifier#next_temporary_identifier
  # because we need the inventory,pubtype and lang in addition to the publication
  # - *Args* :
  #   - +collection+ -> cts inventory
  #   - +template+-> urn template
  #   - +pubtype+ -> edition or translation
  #   - +lang+ -> language code of the edition or translation
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

  ###########################################
  # Public Instance Method Overrides
  ###########################################

  # @overrides Identifier#titleize
  # To set the title from the CTS inventory information
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
    return []
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


  ###########################################
  # CTS Identifier specific Instance Methods
  ###########################################

  # responds to an interface request to retitle the file
  # by updating the label for it in its related text inventory
  def update_title new_title,lang='eng'
    self.related_inventory.update_version_label(self.urn_attribute, title, lang)
  end

  # retrieve the language of the identifier content
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
  
  # Return the identifier formatted as full urn for inclusion in an XML attribute
  def urn_attribute
     return IDENTIFIER_PREFIX + self.to_urn_components.join(":")
  end

  # Return the work level urn for this identifer
  def work_urn
    urn_obj = CTS::CTSLib.urnObj(self.urn_attribute)
    work_urn = IDENTIFIER_PREFIX + urn_obj.getTextGroup() + '.' + urn_obj.getWork(false)
    return work_urn
  end
  

  # Return the inventory name
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

  # check to see if any citations have been extracted in the publication
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


  # return the related CTSInventory identifier
  def related_inventory
    self.publication.identifiers.select{|i| (i.class == CTSInventoryIdentifier)}.last
  end

  # split a urn identifier into its components
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
  
  # default xslt for displaying an annotation view of a CTS passage
  def passage_annotate_xslt
    File.read(File.join(Rails.root,%w{data xslt cts cts_annotate.xsl}))
  end
  
  # default xslt for retrieving the subref of a CTS passage
  def passage_subref_xslt_file
    File.join(Rails.root,%w{data xslt cts passage_to_subref.xsl})
  end
end
