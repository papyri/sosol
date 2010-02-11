class DDBIdentifier < Identifier  
  PATH_PREFIX = 'DDB_EpiDoc_XML'
  COLLECTION_XML_PATH = 'DDB_SGML/collection.xml'
  
  FRIENDLY_NAME = "Text"
  
  IDENTIFIER_NAMESPACE = 'ddbdp'
  TEMPORARY_COLLECTION = '0500'
  
  XML_VALIDATOR = JRubyXML::EpiDocP5Validator
  
  # defined in vendor/plugins/rxsugar/lib/jruby_helper.rb
  acts_as_leiden_plus

  class CollectionXML
    include Singleton
    
    attr_reader :collection_xml, :rexml_document
    
    def initialize
      canonical_repo = Repository.new
      @collection_xml = canonical_repo.get_file_from_branch(
                        COLLECTION_XML_PATH, 'master')
      @rexml_document = REXML::Document.new(@collection_xml)
    end
  end
  
  def titleize
    ddb_series_number, ddb_volume_number, ddb_document_number =
      to_components
    ddb_collection_name = 
      self.class.ddb_series_to_human_collection(ddb_series_number)

    # strip leading zeros
    ddb_document_number.sub!(/^0*/,'')

    title = 
      [ddb_collection_name, ddb_volume_number, ddb_document_number].join(' ')
  end
  
  def id_attribute
    ddb_series_number, ddb_volume_number, ddb_document_number =
      to_components
    ddb_collection_name = 
      self.class.ddb_series_to_human_collection(ddb_series_number)
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
    ddb_collection_name = 
      self.class.ddb_series_to_collection(ddb_series_number)
    
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
  
  def self.get_collection_xml
    CollectionXML.instance.collection_xml
  end

  # map DDB series number to DDB collection name using collection.xml
  def self.ddb_series_to_collection(ddb_series_number)
    # FIXME: put in canonical collection.xml
    if ddb_series_number.to_i == 500
      return 'sosol'
    else
      # collection_xml = get_collection_xml
      xpath_result = REXML::XPath.first(CollectionXML.instance.rexml_document,
        "/rdf:RDF/rdf:Description[@rdf:about = 'Perseus:text:1999.05.#{ddb_series_number}']/text[1]/text()")
    
      return xpath_result.nil? ? nil : xpath_result.to_s
    end
  end
  
  # map DDB human collection name to DDB series number using collection.xml
  def self.ddb_human_collection_to_series(ddb_collection_name)
    # collection_xml = get_collection_xml
    #[@rdf:about = 'Perseus:text:1999.05.#{ddb_series_number}']
    xpath_result = REXML::XPath.first(CollectionXML.instance.rexml_document,
      "/rdf:RDF/rdf:Description/dcterms:isVersionOf[@rdf:resource = 'Perseus:abo:pap,#{ddb_collection_name}']/..")
    xpath_result.attributes['rdf:about'].sub(/^Perseus:text:1999.05./,'')
  end
  
  def self.ddb_series_to_human_collection(ddb_series_number)
    # FIXME: put in canonical collection.xml
    if ddb_series_number.to_i == 500
      return 'SoSOL'
    else
      # collection_xml = get_collection_xml
      xpath_result = REXML::XPath.first(CollectionXML.instance.rexml_document,
        "/rdf:RDF/rdf:Description[@rdf:about = 'Perseus:text:1999.05.#{ddb_series_number}']/dcterms:isVersionOf")
      xpath_result.attributes['rdf:resource'].sub(/^Perseus:abo:pap,/,'')
    end
  end
  
  def self.collection_names
    collection_names = []
    collection_xml = get_collection_xml
    versions = JRubyXML.apply_xpath(collection_xml,
      "/rdf:RDF/rdf:Description/dcterms:isVersionOf", true)
    versions.each do |version|
      collection_names << 
        version[:attributes]['rdf:resource'].sub(/^Perseus:abo:pap,/,'')
    end
    return collection_names.sort
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
    begin
      transformed = DDBIdentifier.xml2nonxml(abs)
    rescue Exception => e
      if e.message.to_s =~ /^dk\.brics\.grammar\.parser\.ParseException: parse error at character (\d+)/
        return e.message.to_s + "\n" + 
          DDBIdentifier.parse_exception_pretty_print(abs, $1.to_i)
      end
    end
    return transformed
  end
  
  def set_leiden_plus(leiden_plus_content, comment)
    # transform back to XML
    xml_content = self.leiden_plus_to_xml(
      leiden_plus_content)
    # commit xml to repo
    self.set_xml_content(xml_content, :comment => comment)
  end
  
  def is_reprinted?
    xpath_result = REXML::XPath.first(REXML::Document.new(self.xml_content),
      "/TEI/text/body/head/ref[@type='reprint-in']")
    return xpath_result.nil? ? false : true
  end
  
  # Override REXML::Attribute#to_string so that attributes are defined
  # with double quotes instead of single quotes
  REXML::Attribute.class_eval( %q^
    def to_string
      %Q[#@expanded_name="#{to_s().gsub(/"/, '&quot;')}"]
    end
  ^ )
  
  def leiden_plus_to_xml(content)
    # a lot of these changes are to make multiple div/ab docs work
    # transform the Leiden+ to XML
    
    begin
      nonx2x = DDBIdentifier.nonxml2xml(content)
    rescue Exception => e
      if e.message.to_s =~ /^dk\.brics\.grammar\.parser\.ParseException: parse error at character (\d+)/
        return e.message.to_s + "\n" #+ session[:templeiden]
         # DDBIdentifier.parse_exception_pretty_print(content, $1.to_i)
      end
    end
    
    nonx2x.sub!(/ xmlns:xml="http:\/\/www.w3.org\/XML\/1998\/namespace"/,'')
    transformed_xml_content = REXML::Document.new(
      nonx2x)
    # fetch the original content
    original_xml_content = REXML::Document.new(self.xml_content)
    
    #count the number of divs in the text and loop through and delete each - couldn't get xpath to do all at once
    
    div_original_edition = original_xml_content.get_elements('/TEI/text/body/div[@type = "edition"]/div')
    
    del_loop_cnt = 0
    nbr_to_del = div_original_edition.length
    until del_loop_cnt == nbr_to_del 
      original_xml_content.delete_element('/TEI/text/body/div[@type = "edition"]/div')
      del_loop_cnt+=1
    end
    
    #repeat for abs if file is set up that way
    
    ab_original_edition = original_xml_content.get_elements('/TEI/text/body/div[@type = "edition"]/ab')
    
    del_loop_cnt = 0
    nbr_to_del = ab_original_edition.length
    until del_loop_cnt == nbr_to_del 
      original_xml_content.delete_element('/TEI/text/body/div[@type = "edition"]/ab')
      del_loop_cnt+=1
    end
    
    # add modified abs to edition
    modified_abs = transformed_xml_content.elements[
      '/wrapab']
    
    original_edition =  original_xml_content.elements[
      '/TEI/text/body/div[@type = "edition"]']
    
    #put loop in because previous did not work with multiple because destructive to array
    #loop through however many need to add and always add the first one in the array which gets deleted
    loop_cnt = 0
    nbr_to_add = modified_abs.length
    until loop_cnt == nbr_to_add 
      original_edition.add_element(modified_abs[0])
      loop_cnt+=1
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
