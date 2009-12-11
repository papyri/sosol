class DDBIdentifier < Identifier  
  PATH_PREFIX = 'DDB_EpiDoc_XML'
  COLLECTION_XML_PATH = 'DDB_SGML/collection.xml'
  
  IDENTIFIER_NAMESPACE = 'ddbdp'
  TEMPORARY_COLLECTION = '0500'
  
  XML_VALIDATOR = JRubyXML::EpiDocP5Validator
  
  # defined in vendor/plugins/rxsugar/lib/jruby_helper.rb
  acts_as_leiden_plus


  def self.friendly_name
    return "Text"
  end
  
  def titleize
    ddb_series_number, ddb_volume_number, ddb_document_number =
      to_components
    ddb_collection_name = ddb_series_to_human_collection(ddb_series_number)

    # strip leading zeros
    ddb_document_number.sub!(/^0*/,'')

    title = 
      [ddb_collection_name, ddb_volume_number, ddb_document_number].join(' ')
  end
  
  def id_attribute
    ddb_series_number, ddb_volume_number, ddb_document_number =
      to_components
    ddb_collection_name = ddb_series_to_human_collection(ddb_series_number)
    ddb_collection_name.downcase!
    return [ddb_collection_name, ddb_volume_number, ddb_document_number].join('.')
  end
  
  def n_attribute
    return to_components.join(';')
  end
  
  def xml_title_text
    id_attribute
  end
  
  def to_path
    path_components = [ PATH_PREFIX ]
    
    ddb_series_number, ddb_volume_number, ddb_document_number =
      to_components
      
    # switch commas to dashes
    # e.g. 0001:13:2230,1 => bgu/bgu.13/bgu.13.2230-1.xml 
    ddb_document_number.tr!(',','-')
    
    # switch forward slashes to underscores
    # e.g. 0014:2:1964/1967 => o.bodl/o.bodl.2/o.bodl.2.1964_1967.xml
    ddb_document_number.tr!('/','_')
      
    # e.g. 0001 => bgu
    ddb_collection_name = ddb_series_to_collection(ddb_series_number)
    
    if ddb_collection_name.nil?
      raise "DDB Collection Name Not Found"
    end
    
    # e.g. bgu.10
    ddb_volume_path = ddb_collection_name + '.' + ddb_volume_number
    # e.g. bgu.10.1901.xml
    ddb_xml_path_components = []
    ddb_xml_path_components << ddb_collection_name
    ddb_xml_path_components << ddb_volume_number unless ddb_volume_number.empty?
    ddb_xml_path_components << ddb_document_number << 'xml'
    ddb_xml_path = ddb_xml_path_components.join('.')
    
    path_components << ddb_collection_name
    path_components << ddb_volume_path unless ddb_volume_number.empty?
    path_components << ddb_xml_path
    
    # e.g. DDB_EpiDoc_XML/bgu/bgu.10/bgu.10.1901.xml
    return File.join(path_components)
  end
  
  def get_collection_xml
    canonical_repo = Repository.new
    collection_xml = canonical_repo.get_file_from_branch(
                      COLLECTION_XML_PATH, 'master')
  end

  # map DDB series number to DDB collection name using collection.xml
  def ddb_series_to_collection(ddb_series_number)
    # FIXME: put in canonical collection.xml
    if ddb_series_number.to_i == 500
      return 'sosol'
    else
      collection_xml = get_collection_xml
      xpath_result = REXML::XPath.first(REXML::Document.new(collection_xml),
        "/rdf:RDF/rdf:Description[@rdf:about = 'Perseus:text:1999.05.#{ddb_series_number}']/text[1]/text()")
    
      return xpath_result.nil? ? nil : xpath_result.to_s
    end
  end
  
  def ddb_series_to_human_collection(ddb_series_number)
    # FIXME: put in canonical collection.xml
    if ddb_series_number.to_i == 500
      return 'SoSOL'
    else
      collection_xml = get_collection_xml
      xpath_result = REXML::XPath.first(REXML::Document.new(collection_xml),
        "/rdf:RDF/rdf:Description[@rdf:about = 'Perseus:text:1999.05.#{ddb_series_number}']/dcterms:isVersionOf")
      xpath_result.attributes['rdf:resource'].sub(/^Perseus:abo:pap,/,'')
    end
  end
  
  def before_commit(content)
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(content),
      JRubyXML.stream_from_file(File.join(RAILS_ROOT,
        %w{data xslt ddb handDesc.xsl})))
  end
  
  def leiden_plus
    abs = DDBIdentifier.preprocess_abs(
      DDBIdentifier.get_abs_from_edition_div(xml_content))
    transformed = DDBIdentifier.xml2nonxml(abs)
    return transformed
  end
  
  def set_leiden_plus(leiden_plus_content, comment)
    # transform back to XML
    xml_content = self.leiden_plus_to_xml(
      leiden_plus_content)
    # commit xml to repo
    self.set_xml_content(xml_content, :comment => comment)
  end
  
  # Override REXML::Attribute#to_string so that attributes are defined
  # with double quotes instead of single quotes
  REXML::Attribute.class_eval( %q^
    def to_string
      %Q[#@expanded_name="#{to_s().gsub(/"/, '&quot;')}"]
    end
  ^ )
  
  def leiden_plus_to_xml(content)
    # transform the Leiden+ to XML
    nonx2x = DDBIdentifier.nonxml2xml(content)
    nonx2x.sub!(/ xmlns:xml="http:\/\/www.w3.org\/XML\/1998\/namespace"/,'')
    
    transformed_xml_content = REXML::Document.new(
      nonx2x)
    # fetch the original content
    original_xml_content = REXML::Document.new(self.xml_content)

    # inject the transformed content into the original content
    # delete original abs
    original_xml_content.delete_element('/TEI/text/body/div[@type = "edition"]//ab')
    
    # add modified abs to edition
    modified_abs = transformed_xml_content.elements[
      '/wrapab']
    original_edition =  original_xml_content.elements[
      '/TEI/text/body/div[@type = "edition"]']
    modified_abs.each do |ab|
      original_edition.add_element(ab)
    end
    
    # write back to a string
    modified_xml_content = ''
    original_xml_content.write(modified_xml_content)
    return modified_xml_content
  end

  def preview
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(self.xml_content),
      JRubyXML.stream_from_file(File.join(RAILS_ROOT,
        %w{data xslt pn start-div-portlet.xsl})))
  end
end
