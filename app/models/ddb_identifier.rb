class DDBIdentifier < Identifier
  DDB_PATH_PREFIX = 'DDB_EpiDoc_XML'
  COLLECTION_XML_PATH = 'DDB_SGML/collection.xml'
  
  
  def to_path
    path_components = [ DDB_PATH_PREFIX ]
    trimmed_name = name.sub(/^oai:papyri.info:identifiers:ddbdp:/, '')
    components = trimmed_name.split(':')
    ddb_series_number = components[0].to_s
    ddb_volume_number = components[1].to_s
    ddb_document_number = components[2].to_s
    
    ddb_collection_name = ddb_series_to_collection(ddb_series_number)
    
    ddb_volume_path = ddb_series_number + '.' + ddb_document_number
    ddb_xml_path = [ddb_series_number, ddb_volume_number, ddb_document_number,
                    'xml'].join('.')
    
    path_components << ddb_series_number << ddb_volume_path << ddb_xml_path
    
    return path_components.join('/')
  end
  
  # map DDB series number to DDB collection name using collection.xml
  def ddb_series_to_collection(ddb_series_number)
    collection_xml = Repository.new.get_file_from_branch(
                      COLLECTION_XML_PATH, 'master')
  end
end