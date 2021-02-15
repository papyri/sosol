class CTSIdentifier < Identifier  
  # This is a superclass for objects using CTS Identifiers, including
  # shared constants and methods. No instances of CTSIdentifier should be
  # created. 
  FRIENDLY_NAME = "Text"
  
  IDENTIFIER_PREFIX = 'urn:cts:' 
  IDENTIFIER_NAMESPACE = ''
  TEMPORARY_COLLECTION = 'TempTexts'
  TEMPORARY_TITLE = 'New Transcription'
  
  def titleize
    title = nil
    if (self.name =~ /#{self.class::TEMPORARY_COLLECTION}/)
       title = self.class::TEMPORARY_TITLE
    else  
      begin
        # if we don't have a publication associated with identifier yet, we're most likely
        # looking for the title for the parent 'publication' which probably should be the work title
        # and not the version-specific label
        if nil == self.publication
          title = CTS::CTSLib.workTitleForUrn(self.inventory,self.urn_attribute)
        else
          title = CTS::CTSLib.versionTitleForUrn(self.inventory,self.urn_attribute)
        end
      rescue StandardError => e
        Rails.logger.error("Error retrieving title: #{e.class.to_s}, #{e.to_s}")
      end
    end
    if (title.nil?)
      title = self.name
    end
    return title
  end

  def self.new_from_template(publication,inventory,urn,pubtype,lang)
    temp_id = self.new(:name => self.next_temporary_identifier(inventory,urn,pubtype,lang))
    Rails.logger.info("adding identifier to pub #{temp_id}")
    temp_id.publication = publication 
    temp_id.save!
    initial_content = temp_id.file_template
    temp_id.set_content(initial_content, :comment => 'Created from SoSOL template')
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
    Rails.logger.info("adding identifier to pub #{temp_id}")
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
    newUrn = "urn:cts:" + urnObj.getTextGroup(true) + "." + urnObj.getWork(false) 
    Rails.logger.info("New urn:#{newUrn}")
    document_path = collection + "/" + CTS::CTSLib.pathForUrn(newUrn,pubtype)
    editionPart = ".#{self::TEMPORARY_COLLECTION}-#{lang}-#{year}-"
    latest = self.where('name like ?', "#{document_path}%").order(name: :desc).limit(1).first
    if latest.nil?
      # no constructed id's for this year/class
      document_number = 1
    else
      Rails.logger.info("------Last component" + latest.to_components.last.split(/[\.;]/).last )
      document_number = latest.to_components.last.split(/[\-;]/).last.to_i + 1
    end
    editionPart = editionPart + document_number.to_s
    # HACK for IDigGreek - just keep the original edition info
    editionPart = urnObj.getVersion(false)
    return "#{document_path}#{editionPart}"
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
  
  def reprinted_in
    return REXML::XPath.first(REXML::Document.new(self.xml_content),
      "/TEI/text/body/head/ref[@type='reprint-in']/@n")
  end
  
  def is_reprinted?
    return reprinted_in.nil? ? false : true
  end
  
  def urn_attribute
     return IDENTIFIER_PREFIX + self.to_urn_components.join(":")
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
  
  def has_related_citations
      cites = self.publication.identifiers.select{|i| (i.class == CitationCTSIdentifier)}
      return cites.size() > 0
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
    Rails.logger.info(temp_components.inspect)
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
    Rails.logger.info("PATH:" + temp_components.inspect)
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
  
end
