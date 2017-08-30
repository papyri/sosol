#  Provides methods for interacting with a collection service
#  configuration provided in the 'collections.yml' file
#  delegates collection service interactions to the RDA ruby-collections-client
#  gem (https://github.com/RDACollectionsWG/ruby-collections-client)
#  this class provides the glue between that and SoSOL
module CollectionsHelper

  require 'rda-collections-client'

  # Read the collections.yml config file and return the parsed config settings
  # - *Returns*:
  #   - the config hash  
  def self.get_config
    unless defined? @config
      @config = YAML::load(ERB.new(File.new(File.join(Rails.root, %w{config collections.yml})).read).result)[Rails.env]
    end
    return @config
  end

  # Check to see if a collection service is enabled per the config
  # - *Args*:
  #   +config_file+ -> the parsed configuration hash
  # - *Returns*:
  #   - true if enabled false if not
  def self.enabled?(config_file)
    config_file['collections_api_host'] && config_file['collections_api_host'] != ''
  end

  # Make a link to a collection 
  # - *Args*:
  #   +coll+ -> the collection
  #   +member+ -> a member object
  # - *Returns*: 
  #   - if a memeber was requested, returns a link to that member
  #     otherwise returns a link to all members in the collection
  def self.make_data_link(coll,member=nil)
    config_file = get_config()
    if enabled?(config_file)
      link = "#{config_file['collections_api_scheme']}://#{config_file['collections_api_host']}#{config_file['collections_api_base_path']}collections/#{coll.id}/members"
      unless member.nil? 
        mid = member_id_for(member)
        link = "#{link}/#{mid}" 
      end
    else
      link = nil
    end
    return link
  end

  # Get an instance of the api client
  # - *Returns:*:
  #   - an api client or nil if disabled or invalid config
  # - *Raises*:
  #   - Exception only if config sets "raise_errors" to true
  #     and a client could not be created, otherwise fails quietly 
  #     and returns nil  
  def self.get_api_instance
    config_file = get_config()
    if enabled?(config_file)
      config = CollectionsClient::Configuration.new()
      config.host = config_file['collections_api_host']
      config.base_path = config_file['collections_api_base_path']
      config.scheme = config_file['collections_api_scheme']
      config.debugging = config_file['collections_api_debugging']
      return CollectionsClient::ApiClient.new(config)
    else
      if config_file['raise_errors']
        raise Exception.new("No Collections API Client Defined")
      else 
        Rails.logger.info("Collection API Client disabled")
        return nil
      end
    end
  end

  # Get an instance of the api client for collections operations
  # - *Returns:*:
  #   - an api client or nil if disabled or invalid config
  def self.get_collections_api
    api_client = get_api_instance()
    if api_client.nil? 
      return nil
    else
      return CollectionsClient::CollectionsApi.new(api_client)
    end
  end

  # Get an instance of the api client for member operations
  # - *Returns:*:
  #   - an api client or nil if disabled or invalid config
  def self.get_members_api
    api_client = get_api_instance()
    if api_client.nil?
      return nil
    else
      return CollectionsClient::MembersApi.new(api_client)
    end
  end

  # Add an object to a collection
  # - *Args*:
  #   +collection+ -> the Collection to add to
  #   +object+ -> the object to add to the collection
  #   +create_if_missing+ -> boolean flag to request creation of collection
  #                          if it doesn't exist yet
  # - *Raises:*:
  #   - an Exception if put fails
  def self.put_to_collection(collection, object, create_if_missing=true)
    config = get_config
    api_client = get_members_api()
    if api_client.nil?
      Rails.logger.info("No Collections API Client Defined")
      return
    end
    member = CollectionsClient::MemberItem.new
    member.id = member_id_for(object)
    member.location = "#{config['local_item_base_path']}/#{object.id}"
    member.datatype = object.class.to_s
    member.mappings = CollectionsClient::CollectionItemMappingMetadata.new()
    member.mappings.date_added = Time.now.iso8601
    if object.mimetype == 'application/xml'
      member.location = member.location + "?format=xml"
    end
    begin
      result = api_client.collections_id_members_post(collection.id,member)
    rescue CollectionsClient::ApiError => e
      if e.code == 404 && create_if_missing
        if (self.post_collection(collection))
          api_client.collections_id_members_post(collection.id,[member])
        end
      else
        Rails.logger.error(e)
        raise e
      end
    end
  end

  # Add a new collection
  # - *Args*:
  #   +collection+ -> the Collection to add
  def self.post_collection(collection)
    config = get_config
    api_client = get_collections_api()
    if api_client.nil?
      Rails.logger.info("No Collections API Client Defined")
      return
    end
    return api_client.collections_post([collection])
  end

  # Get all members of a collection (used for testing only)
  # - *Args*:
  #   +collection_id+ -> the id of the collection
  # - *Returns*:
  #   - the list of collection members
  def self.get_collection_members(collection_id)
    config = get_config
    api_client = get_members_api()
    if api_client.nil?
      Rails.logger.info("No Collections API Client Defined")
      return
    end
    return api_client.collections_id_members_get(collection_id).contents
  end

  # Delete a member item from a collection
  # - *Args*:
  #   +collection+ -> the collection to delete from
  #   +mid+ -> the id of the member item to be deleted
  def self.delete_from_collection(collection, mid)
    api_client = get_members_api()
    if api_client.nil?
      Rails.logger.info("No Collections API Client Defined")
      return nil
    end
    begin
      result = api_client.collections_id_members_mid_delete(collection.id,mid)
    rescue
    end
  end

  # Delete a collection
  # - *Args*:
  #   +collection+ -> the collection to delete
  def self.delete_collection(collection)
    api_client = get_collections_api()
    if api_client.nil?
      Rails.logger.info("No Collections API Client Defined")
      return nil
    end
    begin
      result = api_client.collections_id_delete(collection.id)
    rescue
    end
  end

  # Make a new collection object
  # - *Args*:
  #   +object+ -> the object the collection is for
  #   +datatype+ -> optional datatype specifier
  # - *Returns*:
  #   - the collection object
  def self.make_collection(object, datatype=nil)
    pid = pid_for(object, datatype)
    if object.respond_to?('full_name')
      title = "Perseids User Data By #{object.full_name}"
    elsif object.respond_to?('title')
      title = object.title
    elsif object.respond_to?('id')
      title = "Perseids #{datatype} Annotations on #{object.id}"
    else
      title = "Unknown Collection Type"
    end
    return build_collection_object(pid, {'title'=>title, 'datatype' => datatype})
  end

  # Make a pseudo-pid for a SoSOL object
  # - *Args*:
  #   +object+ -> the object to identify
  #   +datatype+ -> optional datatype specifier
  # - *Returns*:
  #   - a pseudo pid string
  def self.pid_for(object, datatype=nil)
    # eventually we want to use a real pid minting service
    local_id = object.id.to_s
    type = object.class.to_s
    config_file = get_config()
    pid_prefix = config_file['pid_prefix']
    pid = URI.escape("#{pid_prefix}/#{type}")
    unless datatype.nil?
      pid = pid + URI.escape("/" + datatype)
    end
    pid = pid + URI.escape("/" + local_id)
    return pid
  end

  # Make an identifier for a member item in a collection
  # if the object itself provides a pid method it uses that
  # otherwise it mints a pseudo-pid
  # - *Args*:
  #   +object+ -> the object to identify
  # - *Returns*:
  #   - the id
  def self.member_id_for(object)
    object_pid = object.pid()
    if object_pid.nil?
      object_pid = pid_for(object)
    end
    return URI.escape(object_pid)
  end

  # Build a new collection object
  # - *Args*:
  #   +pid+ -> the PID for the collection
  #   +params+ -> parameters (currently only title and datatype are supported)
  # - *Returns*:
  #    - the collection object
  def self.build_collection_object(pid, params)
    collection = CollectionsClient::CollectionObject.new
    collection.id = pid
    collection.capabilities = CollectionsClient::CollectionCapabilities.new
    collection.capabilities.is_ordered = false
    collection.capabilities.appends_to_end = true
    collection.capabilities.supports_roles = false
    collection.capabilities.membership_is_mutable = true
    collection.capabilities.properties_are_mutable = false
    collection.capabilities.restricted_to_type = params['datatype'].nil? ? '' : params['datatype']
    collection.capabilities.max_length = -1
    collection.properties = CollectionsClient::CollectionProperties.new
    #collection.properties.date_created = Time.now.utc
    collection.properties.license = "https://creativecommons.org/licenses/by-sa/4.0/"
    collection.properties.has_access_restrictions = false
    collection.properties.model_type = "http://rd-alliance.org/ns/collection"
    collection.properties.description_ontology = "http://purl.org/dc/terms/"
    collection.properties.member_of = []
    collection.properties.ownership = "http://perseids.org"
    collection.description = {"title" => params['title'] }
    return collection
  end

end
