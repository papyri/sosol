module CollectionsHelper

  require 'rda-collections-client'

  def self.get_config
    unless defined? @config
      @config = YAML::load(ERB.new(File.new(File.join(Rails.root, %w{config collections.yml})).read).result)[Rails.env]
    end
    return @config
  end

  def self.get_api_instance
    unless defined? @api_client
      config_file = get_config()
      if config_file['collections_api_host'] && config_file['collections_api_host'] != ''
        config = CollectionsClient::Configuration.new()
        config.host = config_file['collections_api_host']
        config.base_path = config_file['collections_api_base_path']
        config.scheme = config_file['collections_api_scheme']
        @api_client = CollectionsClient::ApiClient.new(config)
      else
        @api_client = nil
      end
    end
    return @api_client
  end

  def self.get_collections_api
    unless defined? @collections_api
      api_client = get_api_instance
      if api_client.nil?
        @collections_api = nil
        Rails.logger.info("No Collections API Client Defined")
      else
        @collections_api = CollectionsClient::CollectionsApi.new(api_client)
      end
      return @collections_api
    end
  end

  def self.get_members_api
    unless defined? @members_api
      api_client = get_api_instance
      if api_client .nil?
        @members_api = nil
        Rails.logger.info("No Collections API Client Defined")
      else
        @members_api = CollectionsClient::MembersApi.new(api_client)
      end
      return @members_api
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
    begin
      result, code, headers = api_client.collections_id_member_post_with_http_info(collection_id,member)
      if code != 202
          raise Exception.new("Unable to add item to collection. Received code #{code}")
      end
    rescue CollectionsClient::ApiError => e 
      Rails.logger.error(e) 
      raise Exception.new("Unable to add item to collection. Received error #{e}")
    end
  end

  def self.delete_from_collection(collection_id, mid)
    api_client = get_members_api()
    if api_client.nil?
      Rails.logger.info("No Collections API Client Defined")
      return
    end
    begin
      result, code, headers = api_client.collections_id_member_delete_with_http_info(collection_id,mid)
      if code != 200 && code != 202
          raise Exception.new("Unable to remove item from collection. Received code #{code}")
      end
    rescue CollectionsClient::ApiError => e 
      Rails.logger.error(e) 
      raise Exception.new("Unable to remove item from collection. Received error #{e}")
    end
  end

  def self.delete_collection(collection_id)
    api_client = get_collections_api()
    if api_client.nil?
      Rails.logger.info("No Collections API Client Defined")
      return
    end
    begin
      result, code, headers = api_client.collections_id_delete_with_http_info(collection_id)
      if code != 200 && code != 202
          raise Exception.new("Unable to remove collection. Received code #{code}")
      end
    rescue CollectionsClient::ApiError => e 
      Rails.logger.error(e) 
      raise Exception.new("Unable to remove collection. Received error #{e}")
    end
  end


  def self.get_user_collection(user, create_if_missing=false)
    api_client = get_collections_api()
    if api_client.nil?
      Rails.logger.info("No Collections API Client Defined")
      return
    end
    pid = pid_for(user.id, user.class.to_s)
    collection, code, headers = api_client.collections_id_get_with_http_info(pid)
    if code == 404 && create_if_missing
      # build a CollectionObject
      collection = CollectionsClient::Collection.new
      collection.id = pid
      collection.capabilities.is_ordered = false
      collection.capabilities.appends_to_end = true
      collection.capabilities.supports_roles = false
      collection.capabilities.membership_is_mutable = true
      collection.capabilities.metadata_is_mutable = false
      collection.capabilities.restricted_to_type = ""
      collection.capabilities.max_length = -1
      collection.properties.license = "https://creativecommons.org/licenses/by-sa/4.0/"
      collection.properties.has_access_restrictions = false
      collection.properties.model_type = "http://rd-alliance.org/ns/collection"
      collection.properties.description_ontology = "http://purl.org/dc/terms/"
      collection.properties.member_of = []
      collection.ownership = user.uri
      collection.description = {"title" => "Collection of Perseids Data Object Created by #{user.full_name}" } 
      result, code, headers = get_collections_api().collections_post_with_http_info(collection)
    end
    if code != 200 || code != 202
      raise Exception.new("User Collection Not Found")
    end
    return collection.id
  end

  def self.get_topic_collection(topic=nil, datatype="",create_if_missing=false)
    api_client = get_collections_api()
    if api_client.nil?
      Rails.logger.info("No Collections API Client Defined")
      return
    end
    pid = pid_for(topic, 'topic', datatype)
    collection, code, headers = api_client.collections_id_get_with_http_info(pid)
    if code == 404 && create_if_missing
      # build a CollectionObject
      collection = CollectionsClient::Collection.new
      collection.id = pid
      collection.capabilities.is_ordered = false
      collection.capabilities.appends_to_end = true
      collection.capabilities.supports_roles = false
      collection.capabilities.membership_is_mutable = true
      collection.capabilities.metadata_is_mutable = false
      collection.capabilities.restricted_to_type = datatype
      collection.capabilities.max_length = -1
      collection.properties.license = "https://creativecommons.org/licenses/by-sa/4.0/"
      collection.properties.has_access_restrictions = false
      collection.properties.model_type = "http://rd-alliance.org/ns/collection"
      collection.properties.description_ontology = "http://purl.org/dc/terms/"
      collection.properties.member_of = []
      collection.ownership = "http://perseids.org"
      collection.description = {"title" => "Collection of Perseids Annotations of type #{datatype} on #{topic}"}
      result, code, headers = get_collections_api().collections_post_with_http_info(collection)
    end
    if code != 200 || code != 202
      raise Exception.new("Topic Collection Not Found")
    end
    return collection.id
  end

  def self.pid_for(local_id, type, datatype=nil)
    # eventually we want to use a real pid minting service
    pid = "http://perseids.org/collections/#{type}/"
    unless datatype.nil?
      pid = pid + URI.escape(datatype) + "/"
    end
    pid = pid + URI.escape(local_id.to_s)
    return pid
  end

end
