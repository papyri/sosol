class DDBIdentifier < Identifier  
  PATH_PREFIX = 'DDB_EpiDoc_XML'
  COLLECTION_XML_PATH = 'DDB_SGML/collection.xml'
  
  FRIENDLY_NAME = "Text"
  
  IDENTIFIER_NAMESPACE = 'ddbdp'
  TEMPORARY_COLLECTION = 'sosol'
  
  XML_VALIDATOR = JRubyXML::EpiDocP5Validator
  
  BROKE_LEIDEN_MESSAGE = "Broken Leiden+ below saved to come back to later:\n"
  
  # defined in vendor/plugins/rxsugar/lib/jruby_helper.rb
  acts_as_leiden_plus
  
  def id_attribute
    ddb_collection_name, ddb_volume_number, ddb_document_number =
      self.to_components.last.split(';')
    
    ddb_collection_name.downcase!
    
    return [ddb_collection_name, ddb_volume_number, ddb_document_number].reject{|i| i.empty?}.join('.')
  end
  
  def n_attribute
    return to_components[2..-1].join(';')
  end
  
  def xml_title_text
    self.id_attribute
  end
  
  def self.collection_names_hash
    self.collection_names
    
    unless defined? @collection_names_hash
      @collection_names_hash = {TEMPORARY_COLLECTION => "SoSOL"}
      response = 
        NumbersRDF::NumbersHelper.sparql_query_to_numbers_server_response(
          "prefix dc: <http://purl.org/dc/terms/> construct { ?ddb dc:bibliographicCitation ?bibl} from <rmi://localhost/papyri.info#pi> where {?ddb dc:isPartOf <http://papyri.info/ddbdp> . ?ddb dc:bibliographicCitation ?bibl}\n&default-graph-uri=rmi://localhost/papyri.info#pi&format=rdfxml"
        )
      if response.code == '200'
        @collection_names.each do |collection_name|
          xpath = "/rdf:RDF/rdf:Description[@rdf:about=\"http://papyri.info/ddbdp/#{collection_name}\"]/ns1:bibliographicCitation/text()"
          human_name = 
            NumbersRDF::NumbersHelper.process_numbers_server_response_body(
              response.body, xpath).first
          @collection_names_hash[collection_name] = human_name unless human_name.nil?
        end
      end
    end
    
    return @collection_names_hash
  end
  
  def to_path
    path_components = [ PATH_PREFIX ]
    
    ddb_collection_name, ddb_volume_number, ddb_document_number =
      self.to_components[2..-1].join('/').split(';')
      
    # switch commas to dashes
    # e.g. 0001:13:2230,1 => bgu/bgu.13/bgu.13.2230-1.xml 
    ddb_document_number.tr!(',','-')
    
    # switch forward slashes to underscores
    # e.g. 0014:2:1964/1967 => o.bodl/o.bodl.2/o.bodl.2.1964_1967.xml
    ddb_document_number.tr!('/','_')
    
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
  
  def before_commit(content)
    JRubyXML.pretty_print(
      JRubyXML.stream_from_string(
        JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(content),
          JRubyXML.stream_from_file(File.join(RAILS_ROOT,
            %w{data xslt ddb preprocess.xsl})))
      )
    )
  end
  
  def after_rename(options = {})
    # copy back the content to the original name before we update the header
    if options[:set_dummy_header]
      dummy_header =
        JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(content),
          JRubyXML.stream_from_file(File.join(RAILS_ROOT,
            %w{data xslt ddb dummyize.xsl})),
          :reprint_in_text => self.title,
          :ddb_hybrid_ref_attribute => self.n_attribute
        )
      original = options[:original]
      original.save!
      self.publication.identifiers << original
      
      original.set_xml_content(dummy_header, :comment => "Add dummy header for original identifier '#{original.name}' pointing to new identifier '#{self.name}'")
            
      # need to do on originals too
      self.relatives.each do |relative|
        original_relative = relative.clone
        original_relative.name = original.name
        original_relative.title = original.title
        relative.save!
        
        relative.publication.identifiers << original_relative
        
        # set the dummy header on the relative
        original_relative.set_xml_content(dummy_header, :comment => "Add dummy header for original identifier '#{original.name}' pointing to new identifier '#{self.name}'")
      end
    end
    
    if options[:update_header]
      rewritten_xml =
        JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(content),
          JRubyXML.stream_from_file(File.join(RAILS_ROOT,
            %w{data xslt ddb update_header.xsl})),
          :title_text => self.xml_title_text,
          :filename_text => self.id_attribute,
          :ddb_hybrid_text => self.n_attribute
        )
    
      self.set_xml_content(rewritten_xml, :comment => "Update header to reflect new identifier '#{self.name}'")
    end
  end
  
  def get_broken_leiden(original_xml = nil)
    original_xml_content = original_xml || REXML::Document.new(self.xml_content)
    brokeleiden_path = '/TEI/text/body/div[@type = "edition"]/div[@subtype = "brokeleiden"]/note'
    brokeleiden_here = REXML::XPath.first(original_xml_content, brokeleiden_path)
    if brokeleiden_here.nil?
      return nil
    else
      brokeleiden = brokeleiden_here.get_text.value
      
      return brokeleiden.sub(/^#{Regexp.escape(BROKE_LEIDEN_MESSAGE)}/,'')
    end
  end
  
  def leiden_plus
    original_xml = self.xml_content
    original_xml_content = REXML::Document.new(original_xml)

    # if XML does not contain broke Leiden+ send XML to be converted to Leiden+ and return that
    # otherwise, return nil (client can then get_broken_leiden)
    if get_broken_leiden(original_xml_content).nil?
      abs = DDBIdentifier.preprocess_abs(
        DDBIdentifier.get_abs_from_edition_div(original_xml))
      # transform XML to Leiden+ 
      transformed = DDBIdentifier.xml2nonxml(abs)
      
      return transformed
    else
      return nil
    end
  end
  
  # Returns a String of the SHA1 of the commit
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
    nonx2x = DDBIdentifier.nonxml2xml(content)
        
    nonx2x.sub!(/ xmlns:xml="http:\/\/www.w3.org\/XML\/1998\/namespace"/,'')
    transformed_xml_content = REXML::Document.new(
      nonx2x)
    # fetch the original content
    original_xml_content = REXML::Document.new(self.xml_content)
    
    #deletes XML with broke Leiden+ if it exists
    original_xml_content.delete_element('/TEI/text/body/div[@type = "edition"]/div[@subtype = "brokeleiden"]')
    
    #pull divs in the text and loop through and delete each - couldn't get xpath to do all at once
    
    div_original_edition = original_xml_content.get_elements('/TEI/text/body/div[@type = "edition"]/div')
    
    div_original_edition.each do |div|
      original_xml_content.delete_element('/TEI/text/body/div[@type = "edition"]/div')
    end
    
    #repeat for abs if file is set up that way
    
    ab_original_edition = original_xml_content.get_elements('/TEI/text/body/div[@type = "edition"]/ab')

    ab_original_edition.each do |ab|
      original_xml_content.delete_element('/TEI/text/body/div[@type = "edition"]/ab')
    end
    
    #this is to put only 1 new line at the end of the edition div - without this several new lines may exist
    #being left over after multiple ab/div's deleted above and starts adding more and more if do multiple updates
    loc_nl_original_edition = original_xml_content.elements['/TEI/text/body/div[@type = "edition"]']
    loc_nl_original_edition.text = "\n"
    
    # add modified abs to edition
    modified_abs = transformed_xml_content.elements[
      '/wrapab']
    
    original_edition =  original_xml_content.elements[
      '/TEI/text/body/div[@type = "edition"]']
    
    #put loop in because previous did not work with multiple because destructive to array[0]
    #loop through however many need to add and always add the first one in the array which gets deleted
    loop_cnt = 0
    nbr_to_add = modified_abs.length
    until loop_cnt == nbr_to_add 
      
      if modified_abs[0] == "\n" #means it is a text node not and element
        original_edition.add_text modified_abs[0]
      else
        original_edition.add_element(modified_abs[0])
      end
      
      loop_cnt+=1
    end
    
    # write back to a string
    modified_xml_content = ''
    original_xml_content.write(modified_xml_content)
    return modified_xml_content
  end
  
  def save_broken_leiden_plus_to_xml(brokeleiden, commit_comment = '')
    # fetch the original content
    original_xml_content = REXML::Document.new(self.xml_content)
    #deletes XML with broke Leiden+ if it exists already so can add with updated data
    original_xml_content.delete_element('/TEI/text/body/div[@type = "edition"]/div[@subtype = "brokeleiden"]')
    #set in XML where to add new div tag to contain broken Leiden+ and add it
    basepath = '/TEI/text/body/div[@type = "edition"]'
    add_node_here = REXML::XPath.first(original_xml_content, basepath)
    add_node_here.add_element 'div', {'type'=>'edition', 'subtype'=>'brokeleiden'}
    #set in XML where to add new note tag to contain broken Leiden+ and add it
    basepath = '/TEI/text/body/div[@type = "edition"]/div[@subtype = "brokeleiden"]'
    add_node_here = REXML::XPath.first(original_xml_content, basepath)
    add_node_here.add_element "note"
    #set in XML where to add broken Leiden+ and add it
    basepath = '/TEI/text/body/div[@type = "edition"]/div[@subtype = "brokeleiden"]/note'
    add_node_here = REXML::XPath.first(original_xml_content, basepath)
    brokeleiden = BROKE_LEIDEN_MESSAGE + brokeleiden
    add_node_here.add_text brokeleiden
    
    # write back to a string
    modified_xml_content = ''
    original_xml_content.write(modified_xml_content)
    
    # commit xml to repo
    self.set_xml_content(modified_xml_content, :comment => commit_comment)
  end

  def preview
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(self.xml_content),
      JRubyXML.stream_from_file(File.join(RAILS_ROOT,
        %w{data xslt pn start-div-portlet.xsl})))
  end
end
