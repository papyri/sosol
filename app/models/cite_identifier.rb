require 'uri'

class CiteIdentifier < Identifier  
  # This is a superclass for objects using CITE Identifiers, including
  # shared constants and methods. No instances of CiteIdentifier should be
  # created. 
  FRIENDLY_NAME = "CITE Collection Item"
  IDENTIFIER_PREFIX = 'urn:cite:'
  IDENTIFIER_NAMESPACE = 'cite'

  after_commit :update_collections

  ## create a default title for a cite identifier
  def self.create_title(urn)
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


  ##
  # New from Template creates a new CITE object in an existing CITE Collection.
  # It should check for the existence of the existing CITE Collection on the master, 
  # but not fork from it.
  # Identifier gets created by finding the latest version of all instances of the oject
  # and upping it by one.
  ##
  def self.new_from_template(a_publication)
    temp_id = self.new(:name => Cite::CiteLib.pid(self.class.name,{},self.sequencer))
    temp_id.save!
    initial_content = temp_id.file_template
    comment = I18n.t("identifiers.comment_create_from_template"))
    temp_id.set_content(initial_content, :comment => comment, :actor => (a_publication.owner.class == User) ? a_publication.owner.jgit_actor : a_publication.creator.jgit_actor)
    return temp_id
  end

  def self.new_from_supplied(a_publication,a_agent,a_content,a_comment)
    temp_id = self.new(:name => Cite::CiteLib.pid(self.class.name,{},self.sequencer))
    temp_id.save!
    temp_id.publication = a_publication
    temp_id.set_content(initial_content, :comment => a_comment, :actor => (a_publication.owner.class == User) ? a_publication.owner.jgit_actor : a_publication.creator.jgit_actor)
    return temp_id
  end

  def self.sequencer(a_collection_urn)
    # TODO completely not transaction-safe -- we need to lock the identifiers
    # table if we're going to do this right but really we want to move it out of
    # SoSOL all together
    lookup_path = self.path_for_collection(a_collection_urn)
    latest = self.find(:all,
                       :conditions => ["name like ?", "#{lookup_path}%"],
                       :order => "CAST(SUBSTR(name, #{lookup_path.length+1}) AS SIGNED) DESC",
                       :limit => 1).first
    if latest.nil?
      next_in_squence = 1
    else
      citeurn = Cite::CiteLib.urn_obj(latest.urn_attribute)
      next_in_sequence = citeurn.getObjectId().to_i + 1
    end
    return next_in_sequence
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
    citeurn = Cite::CiteLib.urn_obj(a_urn)
    path = collection_path + citeurn.getObjectId() + "."
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
    self.urn_attribute || self.name
  end

  # return a fragment of the content as requested by the supplied query
  # which is specified in an identifier-specific manner
  # - *Args* :
  #   - +a_query+ -> Query String
  # - *Returns* :
  #   - the requested fragment as a String or Nil if not found
  def fragment(a_query)
    raise "get_fragment not implemented for #{self.class}"
  end

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

  def titleize
    title = self.name
    return title
  end

  def update_collections
     # add to user collection
     # update annotation targets collection
  end

  def set_annotation_targets
     raise "set_annotation_targets is not defined for #{self.class}"
  end

  def add_change_desc(text = "", user_info = self.publication.creator, input_content = nil, timestamp = Time.now.xmlschema)
    # default for CITE identifiers a no-op
    self.content
  end
   
  # make a annotator uri from the owner of the publication
  # TODO MOVE !!
  def make_annotator_uri()
    "#{Sosol::Application.config.site_user_namespace}#{URI.escape(self.publication.creator.name)}"
  end
   
  # Looks for matching identifier
  # - *Args*  :
  #   - +match_id+ -> the canonical identifier we are trying to match (e.g. urn:cite:perseus:pdlann.1)
  #   - +match_user+ -> the User owner we are trying to match
  #   - +match_pub+ -> Either an array of initialization values for the identifier
  #                    Or a call back function which receives the potentially matching
  #                    identifier and returns true or false if it matches
  # - *Returns* :
  #   - array of matching identifiers
  def self.find_matching_identifiers(match_id,match_user,match_pub)
    publication = nil
    ## if urn and key value are supplied we need to check to see if the requested object exists before
    ## creating it
    is_collection_urn = Cite::CiteLib.is_collection_urn?(match_id)
    existing_identifiers = []
    if match_pub.is_a? Array
      match_call = lambda do |p|
        return p.is_match?(match_pub)
      end
    else
      match_call = match_pub
    end


    if ( is_collection_urn )
      if (match_pub)
        lookup_id = path_for_collection(match_id)
        possible_conflicts = self.find(:all,
                       :conditions => ["name like ?", "#{lookup_id}%"],
                       :order => "name DESC")

        actual_conflicts = possible_conflicts.select {|pc|
          begin
            ((pc.publication) &&
              (pc.publication.owner == match_user) &&
              !(%w{archived finalized}.include?(pc.publication.status)) &&
               match_call.call(pc)
            )
          rescue Exception => e
            Rails.logger.error("Error checking for conflicts #{pc.publication.status} : #{e.backtrace}")
          end
        }
        existing_identifiers += actual_conflicts
      end
    # all we have is a collection urn so we must want to create a new object
    elsif (Cite::CiteLib.is_object_urn?(match_id))
      ### if publication exists for a version of this object, bring them to it, otherwise create a new version
      lookup_id = path_for_object_urn(match_id)
      possible_conflicts = self.find(:all,
                     :conditions => ["name like ?", "#{lookup_id}%"],
                     :order => "name DESC")

      actual_conflicts = possible_conflicts.select {|pc|
          begin
            ((pc.publication) &&
             (pc.publication.owner == match_user) &&
             !(%w{archived finalized}.include?(pc.publication.status))
            )
          rescue Exception => e
            Rails.logger.error("Error checking for conflicts #{pc.publication.status} : #{e.backtrace}")
          end
      }
      existing_identifiers += actual_conflicts
    elsif (Cite::CiteLib.is_version_urn?(match_id))
      ### if publication exists for this version of this object, bring them to it, otherwise raise ERROR
      lookup_id = path_for_object_urn(match_id)
      possible_conflicts = self.find(:all,
                     :conditions => ["name like ?", "#{lookup_id}%"],
                     :order => "name DESC")

      actual_conflicts = possible_conflicts.select {|pc|
        begin
          ((pc.publication) &&
             (pc.publication.owner == match_user) &&
             !(%w{archived finalized}.include?(pc.publication.status))
             # TODO we should double check that the one they are editing is based on the same version
             # and raise an error otherwise
          )
        rescue Exception => e
          Rails.logger.error("Error checking for conflicts #{pc.publication.status} : #{e.backtrace}")
        end
      }
      existing_identifiers += actual_conflicts
    else
      raise "Unable to check for conflicts - unknown urn type"
    end # end test on urn type
    return existing_identifiers
  end


  def download_file_name
    self.urn_attribute.sub(IDENTIFIER_PREFIX,'').gsub(/:/,'-') + ".xml"
  end

  def clear_cache
    # no op
    # override in sub classes
  end



end



