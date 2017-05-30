module CollectionsHelper

  require 'rda-collections-client'

  def self.get_config
    unless defined? @config
      @config = YAML::load(ERB.new(File.new(File.join(Rails.root, %w{config collections.yml})).read).result)[Rails.env]
    end
    return @config
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

  def self.put_to_collection(collection_id, object)
    config = get_config
    api_client = get_members_api()
    if api_client.nil?
      Rails.logger.info("No Collections API Client Defined")
      return
    end
    member = CollectionsClient::MemberItem.new
    member.id = pid_for(object.id, object.class.to_s)
    member.location = "#{config['local_item_base_path']}/#{object.id}"
    if object.mimetype == 'application/xml'
      member.location = member.location + "?format=xml"
    end
    result = api_client.collections_id_members_post_with_http_info(collection_id,member)
  end

  def self.delete_from_collection(collection_id, mid)
    api_client = get_members_api()
    if api_client.nil?
      Rails.logger.info("No Collections API Client Defined")
      return nil
    end
    begin
      result = api_client.collections_id_members_mid_delete(collection_id,mid)
    rescue
    end
  end

  def self.delete_collection(collection_id)
    api_client = get_collections_api()
    if api_client.nil?
      Rails.logger.info("No Collections API Client Defined")
      return nil
    end
    begin
      result = api_client.collections_id_delete(collection_id)
    rescue
    end
  end


  def self.get_user_collection(user, create_if_missing=false)
    api_client = get_collections_api()
    if api_client.nil?
      Rails.logger.info("No Collections API Client Defined")
      return nil
    end
    pid = pid_for(user.id, user.class.to_s)
    begin 
      collection = api_client.collections_id_get(pid)
      if collection.nil? || collection.id.nil?
        # collection not found returns an ApiError 
        # but if the client can't build a collection from the response
        # it just quietly produces a nil so we have to check explicity for that
        raise Exception.new("Invalid Collection")
      end
    rescue CollectionsClient::ApiError => e
      Rails.logger.info(e)
      if create_if_missing
        title = "Collection of Perseids Data Object Created by #{user.full_name}"
        collection = build_collection_object(pid, {'title'=>title, 'datatype' => ''})
        result = api_client.collections_post(collection)
      end
    end
    return collection.nil? ? nil : collection.id
  end

  def self.get_topic_collection(topic=nil, datatype="",create_if_missing=false)
    api_client = get_collections_api()
    if api_client.nil?
      Rails.logger.info("No Collections API Client Defined")
      return nil
    end
    pid = pid_for(topic, 'topic', datatype)
    begin
      collection = api_client.collections_id_get(pid)
      if collection.nil? || collection.id.nil?
        # collection not found returns an ApiError 
        # but if the client can't build a collection from the response
        # it just quietly produces a nil so we have to check explicity for that
        raise Exception.new("Invalid Collection")
      end
    rescue CollectionsClient::ApiError => e
      Rails.logger.info(e)
      if create_if_missing
        # build a CollectionObject
        # if it fails this time let the error raised fall through
        title = "Collection of Perseids Annotations of type #{datatype} on #{topic}"
        collection = build_collection_object(pid, {'title'=> title, 'datatype' => datatype})
        result = api_client.collections_post(collection)
      end
    end
    return collection.nil? ? nil : collection.id
  end

  def self.get_pub_collection(publication, create_if_missing=false)
    api_client = get_collections_api()
    if api_client.nil?
      Rails.logger.info("No Collections API Client Defined")
      return nil
    end
    pid = pid_for(publication.id, 'publication')
    begin
      collection = api_client.collections_id_get(pid)
      if collection.nil? || collection.id.nil?
        # collection not found returns an ApiError 
        # but if the client can't build a collection from the response
        # it just quietly produces a nil so we have to check explicity for that
        raise Exception.new("Invalid Collection")
      end
    rescue CollectionsClient::ApiError => e
      Rails.logger.info(e)
      if create_if_missing
        # build a CollectionObject
        # if it fails this time let the error raised fall through
        title = "Publication " + publication.title
        collection = build_collection_object(pid, {'title'=> title, 'datatype' => ''})
        result = api_client.collections_post(collection)
      end
    end
    return collection.nil? ? nil : collection.id
  end

  def self.pid_for(local_id, type, datatype=nil)
    # eventually we want to use a real pid minting service
    config_file = get_config()
    pid_prefix = config_file['pid_prefix']
    pid = URI.escape("#{pid_prefix}/#{type}")
    unless datatype.nil?
      pid = pid + URI.escape("/" + datatype)
    end
    pid = pid + URI.escape("/" + local_id.to_s)
    Rails.logger.info("PID FOR Produced " + pid)
    return pid
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
    collection.capabilities.restricted_to_type = params['datatype']
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
