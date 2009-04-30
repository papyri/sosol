class DDBIdentifier < Identifier
  DDB_PATH_PREFIX = 'DDB_EpiDoc_XML'
  
  def to_path
    path_components = [ DDB_PATH_PREFIX ]
    trimmed_name = name.sub(/^oai:papyri.info:identifiers:ddbdp:/, '')
    components = trimmed_name.split(':')
    ddb_series_number = components[0].to_s
    ddb_volume_number = components[1].to_s
    ddb_document_number = components[2].to_s
    
    ddb_volume_path = ddb_series_number + '.' + ddb_document_number
    ddb_xml_path = [ddb_series_number, ddb_volume_number, ddb_document_number,
                    'xml'].join('.')
    
    path_components << ddb_series_number << ddb_volume_path << ddb_xml_path
    
    return path_components.join('/')
  end
end