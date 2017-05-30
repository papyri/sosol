require 'uri'

class CiteIdentifier < Identifier  
  # This is a superclass for objects using CITE Identifiers, including
  # shared constants and methods. No instances of CiteIdentifier should be
  # created. 
  FRIENDLY_NAME = "CITE Collection Item"
  IDENTIFIER_PREFIX = 'urn:cite:'
  IDENTIFIER_NAMESPACE = 'cite'

  ##################################################
  # Public Class Method Overrides
  ##################################################

  # @overrides Identifier#create_title
  def self.create_title(a_from)
    now = Time.now
    lookup_path = 'Annotation Publication' + "/" + now.year.to_s + now.mon.to_s + now.day.to_s
    latest = Publication.find(:all,
      :conditions => ["title like ?", "#{lookup_path}%"],
      :order => "created_at DESC",
      :limit => 1).first
    if latest.nil?
      incr = 1
    else
      incr = latest.title.split('/').last.to_i + 1
    end
    temp_title = lookup_path + "/" + incr.to_s
    return temp_title
  end


  # @overrides Identifier#next_temporary_identifier
  # Determines the next identifier  for this class
  # Delegates to the CITE PID Provider
  # - *Returns* :
  #   - identifier name
  def self.next_temporary_identifier
    callback = lambda do |u| return self.sequencer(u) end
    return self.path_for_version_urn(Cite::CiteLib.pid(self.to_s,{},callback))
  end

  ##################################################
  # Public CITE Identifier Only Class Methods
  ##################################################


  # Return the identifier name path for a CiteIdentifier collection URN
  # - *Args* :
  #   - +a_urn+ the collection urn
  # - *Returns* :
  #   - identifier path for the collection part
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

  # Return the identifier name path for a CiteIdentifier Object URN (without version)
  # - *Args* :
  #   - +a_urn+ the cite object urn
  # - *Returns* :
  #   - identifier path for the object part
  def self.path_for_object_urn(a_urn)
    collection_path = path_for_collection(a_urn)
    citeurn = Cite::CiteLib.urn_obj(a_urn)
    path = collection_path + citeurn.getObjectId() + "."
  end

  # Return the identifier name path for a CiteIdentifier Object URN (with version)
  # - *Args* :
  #   - +a_urn+ -> the cite object urn
  # - *Returns* :
  #   - identifier path for the full urn
  def self.path_for_version_urn(a_urn)
    object_path = self.path_for_object_urn(a_urn)
    citeurn = Cite::CiteLib.urn_obj(a_urn)
    return  object_path + citeurn.getVersion()
  end

  # Sequencer method for incrementing identifiers
  # - *Args*:
  #   - +a_collection_urn+ -> cite collection urn
  # - *Returns*
  #   - next in sequence
  def self.sequencer(a_collection_urn)
    lookup_path = self.path_for_collection(a_collection_urn)
    latest = self.find(:all,
      :conditions => ["name like ?", "#{lookup_path}%"],
      :order => "CAST(SUBSTR(name, #{lookup_path.length+1}) AS SIGNED) DESC",
      :limit => 1).first
    if latest.nil?
      next_in_sequence = 1
    else
      citeurn = Cite::CiteLib.urn_obj(latest.urn_attribute)
      next_in_sequence = citeurn.getObjectId().to_i + 1
    end
    return next_in_sequence
  end


  ##################################################
  # Public Instance Method Overrides
  ##################################################

  # Return the identifier formatted for inclusion in an xml:id attribute
  def id_attribute
     # TODO figure out best way to handle urn as id attribute (: not allowed)
     return (IDENTIFIER_PREFIX + self.to_urn_components.join("_")).gsub!(/:/,'_')
  end

  # Return the identifier formatted for inclusion in an xml:id attribute
  def n_attribute
    return id_attribute
  end

  # Default XML title text from the URN
  def xml_title_text
    # TODO lookup title
    self.urn_attribute || self.name
  end

  # Calculate the filepath on the Git Repository for storage
  # of identifier content
  def to_path
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

  # @overrides Identifier#get_catalog_link
  # Currently no catalog for CiteIdentifiers
  def get_catalog_link
    return []
  end

  # @overrides Identifier#titleize
  # just use the identifier name as the default title
  def titleize
    title = self.name
    return title
  end

  # @overrides Identifier#add_change_desc
  # we don't currently record change history in CiteIdentifier objects
  def add_change_desc(text = "", user_info = self.publication.creator, input_content = nil, timestamp = Time.now.xmlschema)
    # default for CITE identifiers a no-op
    self.content
  end

  # @overrides Identifier#download_file_name
  # Get the file name for download of identifier contents
  def download_file_name
    self.urn_attribute.sub(IDENTIFIER_PREFIX,'').gsub(/:/,'-') + ".xml"
  end

  ##################################################
  # Public CITE Identifier Only Instance Methods
  ##################################################

  # Return the identifier formatted as full urn for inclusion in an XML attribute
  def urn_attribute
     return IDENTIFIER_PREFIX + self.to_urn_components.join(":")
  end

  # make a annotator uri from the owner of the parent publication
  def make_annotator_uri()
    "#{Sosol::Application.config.site_user_namespace}#{URI.escape(self.publication.creator.name)}"
  end
   

  # Clear cached model data
  def clear_cache
    # no op
    # override in sub classes
  end

  # @overrides Identifier#as_ro
  def as_ro
    ro = {'aggregates' => [], 'annotations' => []}
    about = []
    derived_from = []
    local_urns = self.publication.ro_local_aggregates()
    topics = self.get_topics()
    topics.each do |t|
      if local_urns[t]
        about << local_urns[t] 
      else
        derived_from << t
      end
    end
    package_obj = {
      'conformsTo' => self.schema,
      'mediatype' => self.mimetype,
      'createdBy' => { 'name' => self.publication.creator.full_name, 'uri' => self.publication.creator.uri }
    }
    if about.size > 0 
      package_obj['content'] = File.join('annotations',self.download_file_name)
      package_obj['about'] = about.uniq
      # a bit of a hack (as if the rest isn't) but we don't 
      # have an appropriate standad motivation for anything except Commentary items
      if self.class == CommentaryCiteIdentifier
        package_obj['oa:motivating'] = 'oa:commenting'
      end
      ro['annotations'] << package_obj
    else 
      package_obj['uri'] = File.join('../data',self.download_file_name)
      if derived_from.size > 0
        prov_file_name = File.join('provenance',self.download_file_name.sub(/\.xml$/,'.prov.jsonld'))
        package_obj['history'] = prov_file_name
        ro['provenance'] = { 'file' => prov_file_name, 'contents' => BagitHelper::generate_prov_doc(self.download_file_name, derived_from.uniq) }
      end
      ro['aggregates'] << package_obj
    end
    return ro
  end

  #############################
  # Private Helper Methods
  #############################

  protected

    # split a urn into parts
    def to_urn_components
      temp_components = self.to_components
      # should give us, e.g.
      # [0] id namespace  - e.g. cite
      # [1] collection namespace = e.g. perseus
      # [2] collection.object.version - e.g. testColl.1.1
      urn_components = []
      urn_components << temp_components[1]
      urn_components << temp_components[2]
      return urn_components
    end

    # @overrides Identifier#add_to_collections
    def add_to_collections
        AddToCollectionsJob.new.async.perform(self.id)
    end

    # @overrides Identifier#update_in_collections
    def update_in_collections
      # default is a noop - updates don't require collection operations
      # update may be necessary if topics were updated though....
    end

    # @overrides Identifier#remove_from_collections
    def remove_from_collections
      # we need to gather the collections here rather than the async job because the identifier 
      # might be gone by the time the async job runs?
      mid = CollectionsHelper::pid_for(self.id,self.class.to_s)
      collections = []
      collections << CollectionsHelper::get_pub_collection(self.publication, false)
      collections << CollectionsHelper::get_user_collection(self.publication.owner, false)
      # remove it from the subject collection
      self.get_topics().each do |c|
        collections << CollectionsHelper::get_topic_collection(c, self.class.to_s, false)
      end
      Rails.logger.info("Removing from collections before destroy")
      RemoveFromCollectionsJob.new.async.perform(collections,mid)
      # TODO we really should have a rollback of this if the destroy ends up failing...
    end

end



