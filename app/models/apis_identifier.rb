class APISIdentifier < Identifier
  
  # minimal definition of this class to support '_publication_selector.haml' partial in commentary helper
  
  IDENTIFIER_NAMESPACE = 'apis'
  TEMPORARY_COLLECTION = 'SoSOL'
  
  FRIENDLY_NAME = "APIS Identifier"
  
  def self.collection_names_hash
    self.collection_names
    
    unless defined? @collection_names_hash
      @collection_names_hash = Hash.new
      @collection_names.each do |collection_name|
        @collection_names_hash[collection_name] = collection_name
      end
    end
    
    return @collection_names_hash
  end
end