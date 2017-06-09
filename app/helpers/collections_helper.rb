module CollectionsHelper

  require 'rda-collections-client'

  def self.get_config
    unless defined? @config
      @config = YAML::load(ERB.new(File.new(File.join(Rails.root, %w{config collections.yml})).read).result)[Rails.env]
    end
    return @config
  end

  def self.make_member_link(coll,member)
    config_file = get_config()
    mid = member_id_for(member)
    return [ coll.description['title'], "#{config_file['collections_api_scheme']}://#{config_file['collections_api_host']}#{config_file['collections_api_base_path']}collections/#{coll.id}/members/#{mid}" ]
  end

  def self.get_api_instance
    config_file = get_config()
    if config_file['collections_api_host'] && config_file['collections_api_host'] != ''
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

  def self.get_collections_api
    api_client = get_api_instance()
    if api_client.nil? 
      return nil
    else
      return CollectionsClient::CollectionsApi.new(api_client)
    end
  end

  def self.get_members_api
    api_client = get_api_instance()
    if api_client.nil?
      return nil
    else
      return CollectionsClient::MembersApi.new(api_client)
    end
  end

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
          api_client.collections_id_members_post(collection.id,member)
        end
      else
        Rails.logger.error(e)
        raise e
      end
    end
  end

  def self.post_collection(collection)
    config = get_config
    api_client = get_collections_api()
    if api_client.nil?
      Rails.logger.info("No Collections API Client Defined")
      return
    end
    return api_client.collections_post(collection)
  end

  def self.get_collection_members(collection_id)
    config = get_config
    api_client = get_members_api()
    if api_client.nil?
      Rails.logger.info("No Collections API Client Defined")
      return
    end
    return api_client.collections_id_members_get(collection_id).contents
  end

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

  def self.make_collection(object, datatype=nil)
    pid = pid_for(object, datatype)
    case object
    when object.respond_to?(:full_name)
      title = "Collection of Perseids Data Object Created by #{object.full_name}"
    when object.respond_to?(:title)
      title = object.title
    when object.respond_to?(:id)
      title = "Collection of Perseids Annotations of type #{datatype} on #{object.id}"
    else
      title = "Unknown Collection Type"
    end
    return build_collection_object(pid, {'title'=>title, 'datatype' => datatype})
  end

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

  def self.member_id_for(object)
    object_pid = object.pid()
    if object_pid.nil?
      object_pid = pid_for(object)
    end
    return URI.escape(object_pid)
  end

  def self.build_collection_object(pid, params)
    collection = CollectionsClient::CollectionObject.new
    collection.id = pid
    collection.capabilities = CollectionsClient::CollectionCapabilities.new
    collection.capabilities.is_ordered = false
    collection.capabilities.appends_to_end = true
    collection.capabilities.supports_roles = false
    collection.capabilities.membership_is_mutable = true
    collection.capabilities.metadata_is_mutable = false
    collection.capabilities.restricted_to_type = params['datatype'].nil? ? '' : params['datatype']
    collection.capabilities.max_length = -1
    collection.properties = CollectionsClient::CollectionProperties.new
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
