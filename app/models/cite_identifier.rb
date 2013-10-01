class CiteIdentifier < Identifier  
  # This is a superclass for objects using CTS Identifiers, including
  # shared constants and methods. No instances of CTSIdentifier should be
  # created. 
  FRIENDLY_NAME = "CITE Collection Item"
  
  IDENTIFIER_PREFIX = 'urn:cite:' 
  IDENTIFIER_NAMESPACE = 'cite'
  
  # must be defined in subclass 
  #  PATH_PREFIX
  #  FILE_TYPE
  
  def titleize
    title = self.name
    return title
  end

  ##
  # New from Template creates a new CITE object in an existing CITE Collection.
  # It should check for the existence of the existing CITE Collection on the master, 
  # but not fork from it.
  # Identifier gets created by finding the latest version of all instances of the oject
  # and upping it by one.
  ##
  def self.new_from_template(a_publication,a_urn,a_init_value)
    Rails.logger.info("new from template for #{a_urn}")
    temp_id = self.new(:name => self.next_object_identifier(a_urn))
    Rails.logger.info("adding identifier to pub #{temp_id}")
    temp_id.publication = a_publication 
    if (! temp_id.collection_exists?)
      raise "Unregistered CITE Collection for #{a_urn}"
    end
    temp_id.save!
    initial_content = temp_id.file_template
    temp_id.set_content(initial_content, :comment => 'Created from SoSOL template')
    temp_id.init_content(a_init_value)
    return temp_id
  end
  
  # initialization method - initializes the object with the supplied string
  def init_content(a_value)
    # default is a no-op - may be implemented in a subclass
  end
  
  #initialization method for a new version of an existing CITE Object
  def init_version_content(a_content)
    # default is just to return the supplied content
    return a_content
  end
  
  ##
  # New from Inventory creates a new version of an existing CITE Object.
  # It should check for the existence of the existing CITE Object on the master, 
  # but not fork from it.
  # Identifier gets created by finding the latest version of all instances of the oject
  # and upping it by one.
  ##
  def self.new_from_inventory(a_publication,a_urn)
    parent_document_path = self.path_for_version_urn(a_urn) 
    parent_id = self.new(:name => parent_document_path)
    # make sure we have a path on master before forking it for this publication 
    if (a_publication.repository.get_file_from_branch(parent_id.to_path, 'master').blank?)
      #raise error
      raise parent_id.to_path + " not found on master"
    end
    temp_id = self.new(:name => self.next_version_identifier(a_urn))
    
    #TODO check to see if parent item is remaining the user's branch at this point

    temp_id.publication = a_publication    
    temp_id.save!
     # initialize a new version of the content from the parent content
    initial_content = temp_id.init_version_content(parent_id.content)
    return temp_id
  end
  
  # get a temporary identifier - use for parent publication only
  def self.next_temporary_identifier(a_collection_urn)
   
  end
  
  # returns the next identifier for a new object in a collection
  def self.next_object_identifier(a_collection_urn)
    lookup_path = self.path_for_collection(a_collection_urn)
    latest = self.find(:all,
                       :conditions => ["name like ?", "#{lookup_path}%"],
                       :order => "publication_id DESC",
                       :limit => 1).first
    next_version_id = 1
    if latest.nil?
      # no constructed id's for this year/class
      next_object_id = 1
    else
      citeurn = Cite::CiteLib.urn_obj(latest.urn_attribute)
      # TODO add support for object prefix
      next_object_id = citeurn.getObjectId().to_i + 1 
    end
    return self.path_for_version_urn(a_collection_urn + "." + next_object_id.to_s + "." + next_version_id.to_s)
  end
  
  #returns the next identifier for a new version of an object in a collection
  def self.next_version_identifier(a_urn)
    lookup_path = self.path_for_object_urn(a_urn)
    latest = self.find(:all,
                       :conditions => ["name like ?", "#{lookup_path}%"],
                       :order => "id DESC",
                       :limit => 1).first
    if latest.nil?
      # if we don't have any identifiers in the db for this object yet, just increment the
      # supplied urn
      citeurn = Cite::CiteLib.urn_obj(a_urn)
    else
      citeurn = Cite::CiteLib.urn_obj(latest.urn_attribute)
    end
    next_version_id = citeurn.getVersion().to_i + 1 
    
    return self.path_for_version_urn(IDENTIFIER_PREFIX + citeurn.getNs() + ":" + citeurn.getCollection() + "." + citeurn.getObjectId() + "." + next_version_id.to_s)
  
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
  
  def collection
    return self.to_components[0]
  end
   
  def related_inventory 
    self.publication.identifiers.select{|i| (i.class == CiteInventoryIdentifier)}.last
  end
  
  def to_urn_components
    temp_components = self.to_components
    # should give us, e.g.
    # [0] id namespace  - e.g. cite
    # [1] collection namespace = e.g. perseus
    # [2] collection.object.version - e.g. testColl.1.1 
    Rails.logger.info("In to_urn_components: " + temp_components.inspect)
    urn_components = []
    urn_components << temp_components[1]
    urn_components << temp_components[2]
    return urn_components
  end
  
  def collection_exists?
    path_components = [ self.class::PATH_PREFIX ]
    temp_components = self.to_components
     # should give us, e.g.
    # [0] id namespace - e.g. cite
    # [1] collection namespace = e.g. perseus
    # [2] collection.object.version - e.g. testcoll.1.1
    ns = temp_components[1]
    
    parts = temp_components[2].split(/\./)
    coll = parts[0]
    objid = parts[1]
    version = parts[2]
       
    path_components << ns
    path_components << coll
    
    # e.g. CITE_OAC_XML/perseus/mycoll
    collection_path = File.join(path_components)
    tree = self.publication.repository.repo.tree('master', [collection_path])
    exists = ! tree.contents.first.nil?
  end
  
  def to_path
    path_components = [ self.class::PATH_PREFIX ]
    temp_components = self.to_components
    Rails.logger.info("PATH:" + temp_components.inspect)
     # should give us, e.g.
    # [0] id namespace - e.g. cite
    # [1] collection namespace = e.g. perseus
    # [2] collection.object.version - e.g. testcoll.1.1
    ns = temp_components[1]
    
    parts = temp_components[2].split(/\./)
    coll = parts[0]
    objid = parts[1]
    version = parts[2]
       
    # e.g. mycoll.1.1.oac.xml
    file_path_components = []
    file_path_components << coll
    file_path_components << objid
    file_path_components << version 
    file_path_components << self.class::FILE_TYPE 
    file_path = file_path_components.join('.')
    
    path_components << ns
    path_components << coll
    path_components << objid
    path_components << file_path
    
    # e.g. CITE_OAC_XML/perseus/mycoll/1/mycoll.1.1.oac.xml
    return File.join(path_components)
  end
  
   ## get a link to the catalog for this identifier  
  def get_catalog_link
    #return "http://catalog.perseus.tufts.edu/perseus.org/xc/search/" + self.urn_attribute
    return ''
  end
  
  ## method which checks the cite object for a key value
  def is_match?(a_value) 
    # default is a no-op which just returns false
    return false
  end
  

  def self.path_for_collection(a_urn)
    # urn looks like urn:cite:namespace:collection[.object[.version]]
    parts = a_urn.split(/:/)
    if (parts.length < 4)
      raise "Invalid collection urn #{a_urn}"
    end
    namespace = parts[2]
    collection = parts[3].sub(/\..*$/,'')
    return IDENTIFIER_NAMESPACE + "/" + namespace + "/" + collection + "."    
  end
  
  def self.path_for_object_urn(a_urn)
    collection_path = path_for_collection(a_urn)
    Rails.logger.info("Path for collection of #{a_urn} = #{collection_path}")
    citeurn = Cite::CiteLib.urn_obj(a_urn)
    path = collection_path + citeurn.getObjectId() + "."
  end
  
  def self.path_for_version_urn(a_urn)
    object_path = self.path_for_object_urn(a_urn)
    citeurn = Cite::CiteLib.urn_obj(a_urn)
    return  object_path + citeurn.getVersion() 
  end
   

end



