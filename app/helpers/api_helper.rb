module ApiHelper

  def self.build_identifier(identifier,content=nil,meta_only=false)
    item = { }
    item[:id] = identifier.id
    item[:type] = identifier.type
    item[:mimetype] = identifier.mimetype
    item[:publication] = identifier.publication.id
    # all api-created pubs should have a community but for backwards
    # compatibility with data created through the ui
    # we need to check to be sure
    if identifier.publication.community
      item[:publication_community_name] = identifier.publication.community.friendly_name
    end
    unless meta_only
      item[:content] = content.nil? ? identifier.content : content
    end
    item
  end

end
