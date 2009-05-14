class DDBIdentifier < Identifier
  include DdbIdentifiersHelper
  
  DDB_PATH_PREFIX = 'DDB_EpiDoc_XML'
  COLLECTION_XML_PATH = 'DDB_SGML/collection.xml'
  
  acts_as_leiden_plus
  
  def to_components
    trimmed_name = name.sub(/^oai:papyri.info:identifiers:ddbdp:/, '')
    components = trimmed_name.split(':')
    ddb_series_number = components[0].to_s
    ddb_volume_number = components[1].to_s
    ddb_document_number = components[2].to_s
    
    # e.g. 0001 => bgu
    ddb_collection_name = ddb_series_to_collection(ddb_series_number)
    
    return [ddb_collection_name, ddb_volume_number, ddb_document_number]
  end
  
  def titleize
    ddb_collection_name, ddb_volume_number, ddb_document_number =
      to_components
    ddb_collection_name.gsub!(/\./,'. ').rstrip!
    title = 
      [ddb_collection_name, ddb_volume_number, ddb_document_number].join(' ')
    return title.titleize
  end
  
  def to_path
    path_components = [ DDB_PATH_PREFIX ]
    
    ddb_collection_name, ddb_volume_number, ddb_document_number =
      to_components
    
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
  
  def xml_content
    return self.content
  end
  
  def set_xml_content(content, comment)
    self.set_content(content, :comment => comment)
  end
  
  def leiden_plus
    content = self.xml_content
    abs = DDBIdentifier.preprocess_abs(
      DDBIdentifier.get_abs_from_edition_div(content))
    transformed = DDBIdentifier.xml2nonxml(abs)
    if transformed =~ /^dk\.brics\.grammar\.parser\.ParseException: parse error at character (\d+)/
      transformed + "\n" + 
        DDBIdentifier.parse_exception_pretty_print(abs, $1.to_i)
    else
      transformed
    end
  end
  
  def set_leiden_plus(leiden_plus_content, comment)
    # transform back to XML
    xml_content = self.leiden_plus_to_xml(
      leiden_plus_content)
    # commit xml to repo
    self.set_xml_content(xml_content, comment)
  end
  
  def leiden_plus_to_xml(content)
    # transform the Leiden+ to XML
    transformed_xml_content = REXML::Document.new(
      DDBIdentifier.nonxml2xml(content))
    # fetch the original content
    original_xml_content = REXML::Document.new(self.xml_content)

    # inject the transformed content into the original content
    # delete original abs
    original_xml_content.delete_element('/TEI.2/text/body/div[@type = "edition"]//ab')
    
    # add modified abs to edition
    modified_abs = transformed_xml_content.elements[
      '/wrapab']
    original_edition =  original_xml_content.elements[
      '/TEI.2/text/body/div[@type = "edition"]']
    modified_abs.each do |ab|
      original_edition.add_element(ab)
    end
    
    # write back to a string
    modified_xml_content = ''
    original_xml_content.write(modified_xml_content)
    return modified_xml_content
  end
end