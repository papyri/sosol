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
    
    # e.g. 0001 => bgu
    ddb_collection_name = ddb_series_to_collection(ddb_series_number)
    
    # e.g. bgu.10
    ddb_volume_path = ddb_collection_name + '.' + ddb_volume_number
    # e.g. bgu.10.1901.xml
    ddb_xml_path = [ddb_collection_name,
                    ddb_volume_number,
                    ddb_document_number,
                    'xml'].join('.')
    
    path_components << ddb_collection_name << ddb_volume_path << ddb_xml_path
    
    # e.g. DDB_EpiDoc_XML/bgu/bgu.10/bgu.10.1901.xml
    return path_components.join('/')
  end
  
  # map DDB series number to DDB collection name using collection.xml
  def ddb_series_to_collection(ddb_series_number)
    canonical_repo = Repository.new
    collection_xml = canonical_repo.get_file_from_branch(
                      COLLECTION_XML_PATH, 'master')
    xpath_result = REXML::XPath.first(REXML::Document.new(collection_xml),
      "/rdf:RDF/rdf:Description[@rdf:about = 'Perseus:text:1999.05.#{ddb_series_number}']/text[1]/text()")
    
    return xpath_result.to_s
  end
  
  def xml_content(publication)
    return publication.user.repository.get_file_from_branch(
      self.to_path, publication.branch)
  end
  
  def set_xml_content(publication, content, comment)
    publication.user.repository.commit_content(self.to_path,
                                               publication.branch,
                                               content,
                                               comment)
  end
end