class TreebankCiteIdentifier < CiteIdentifier   
  include OacHelper

  FRIENDLY_NAME = "Treebank Annotation"
  PATH_PREFIX="CITE_TREEBANK_XML"
  FILE_TYPE="tb.xml"
  ANNOTATION_TITLE = "Treebank Annotation"
  TEMPLATE = "template"
  
  # TODO Validator depends upon treebank format
  XML_VALIDATOR = JRubyXML::PerseusTreebankValidator
  
  def titleize
    # TODO should say Treebank on Target URI
    title = self.name
    return title
  end
  
  def toXmlString xmlObject
    formatter = PrettySsime.new
    formatter.compact = true
    formatter.width = 2**32
    modified_xml_content = ''
    formatter.write xmlObject, modified_xml_content
    modified_xml_content
  end
  
  # initialization method for a new version of an existing Annotation Object
  # adds the creator as a top-level annotator and creates/updates the date
  # @param a_content the original content
  # @return the updated content
  def init_version_content(a_content)
    treebank = REXML::Document.new(a_content).root
    treebank.delete_element("date")
    date = REXML::Element.new("date")
    date.add_text(Time.new.inspect)
    treebank.insert_before("sentence[1]",date)
    creator_uri = make_annotator_uri
    xpath = "annotator/uri"
    all_annotators = REXML::XPath.match(treebank, xpath)
    add = true
    all_annotators.each do |ann|
      if  ann == creator_uri
        add = false
      end
    end
    if (add)
      annotator = REXML::Element.new("annotator")
      short = REXML::Element.new("short")
      short.add_text(self.publication.creator.name)
      name = REXML::Element.new("name")
      name.add_text(self.publication.creator.human_name)
      address = REXML::Element.new("address")
      address.add_text(self.publication.creator.email)
      uri = REXML::Element.new("uri")
      uri.add_text(creator_uri)
      annotator.add_element(short)
      annotator.add_element(name)
      annotator.add_element(address)
      annotator.add_element(uri)
      treebank.insert_before("sentence[1]",annotator)
    end
    
    toXmlString treebank
  end
  
  # templates for treebank files come from repo or service
  # @see init_content
  def file_template
    return ""
  end
  
  # Initializes a treebank template
  # First looks in the repository to see if we already have a template
  # for the requested URN target. If so, we just use that. Otherwise
  # we send a job to the annotation service to create one
  # @param [String] a_value is the initialization value - in this case the target urn 
  def init_content(a_value)
    init_value = a_value.to_s
    begin
      urn_value = init_value.match(/^https?:.*?(urn:cts:.*)$/).captures[0]
      urn_obj = CTS::CTSLib.urnObj(urn_value)
    rescue Exception => e
      # if we get an exception it might be an invalid urn or it might be something that
      # isn't a urn
      if (! a_value =~ /urn:cts:/)
        # not a cts urn, just assume we have to create a new template
        raise "Not a URN"
      else 
        # otherwise raise an error
        raise e
      end
    end
    template = nil
    unless (urn_obj.nil?)
      base_uri = init_value.match(/^(http?:\/\/.*?)\/urn:cts.*$/).captures[0]
      template_path = path_for_target(TEMPLATE,base_uri,urn_obj)
      template = self.publication.repository.get_file_from_branch(template_path, 'master') 
    end
    if (template.nil?)
      raise "Service call not yet implemented"    
    end
    template_init = init_version_content(template)
    # TODO here we need to call the Annotation Service, passing in
    ## the urn of the target passage OR the text to be annotated
    ## call should be asynchronous and supply user email address for notification
    ## for now we will require the user to complete the step to populate the 
    ## template from the service results, but eventually that should be automatic
    self.set_xml_content(template_init, :comment => 'Initializing Content')
  end
  
  # Path for treebank file for target text
  # @param [String] a_type (template or data) 
  # @param [String] a_base_uri the base uri
  # @param [JCtsUrn] a_target_urn
  # @return [String] the repository path
  def path_for_target(a_type,a_base_uri,a_target_urn)
    uri = a_base_uri.gsub(/^http?:\/\//, '')
    parts = []
    #  PATH_PREFIX/type/uri/namespace/textgroup/work/textgroup.work.edition.passage.FILE_TYPE
    parts << PATH_PREFIX
    parts << a_type
    parts << uri
    tgparts = a_target_urn.getTextGroup().split(/:/)
    work  = a_target_urn.getWork(false)
    parts << tgparts[0]
    parts << tgparts[1]
    parts << work
    file_parts = []
    file_parts << tgparts[1]
    file_parts << work
    file_parts <<  a_target_urn.getVersion(false)
    if (a_target_urn.passageComponent)
      file_parts << a_target_urn.getPassage(100)
    end
    file_parts << FILE_TYPE
    parts << file_parts.join(".")
    File.join(parts)
  end
  
  # get a sentence
  # @param [String] a_id the sentence id
  # @return [String] the sentence xml 
  def sentence(a_id)
    t = REXML::Document.new(self.xml_content)
    s = REXML::XPath.first(t,"/treebank/sentence[@id=#{a_id}]")
    toXmlString s
  end
  
  # get descriptive info for a treebank file
  def api_info
    # TODO eventually this will be customized per user/file - for now return the default
    template_path = File.join(RAILS_ROOT, ['data','templates'],
                              "treebank-desc-#{self.format}.xml.erb")
    template = ERB.new(File.new(template_path).read, nil, '-')
    
    format = self.format
    lang = self.language
    size = self.size
    direction = self.direction
    return template.result(binding)
  end
  
  # get the format for the treebank file
  def format
    #TODO - pull from file
    return 'aldt'
  end
  
  
  # get the language for the treebank file
  def language
    #TODO - pull from file
    return 'lat'
  end
  
  # get the number of sentences in the treebank file
  def size
    # TODO - pull from file
    return 100.to_s
  end
  
  
   # get the direction of text in the treebank file
  def direction
    # TODO - pull from file
    return 'ltr'
  end
  
  # api_get responds to a call from the data management api controller
  # @param [String] a_query if not nil, means use the query to 
  #                         return part of the item
  # TODO the query should really be an XPath 
  def api_get(a_query)
    qmatch = /^s=(\d+)$/.match(a_query)
    if (qmatch.nil?)
      raise "Invalid request - no sentence specified in #{a_query}"
    else
      return sentence(qmatch[1])
    end
  end
  
  # api_get responds to a call from the data management api controller
  # @param [String] a_query  parameter containing a querystring
  #                 specific to the identifier type. We use it for TreebankIdentifiers
  #                 to identify the sentence
  # @param [String] a_body the raw body of the post data
  # @param [String] a_comment an update comment
  #
  def api_update(a_query,a_body,a_comment)
    qmatch = /^s=(\d+)$/.match(a_query)
    if (qmatch.size == 2)
      return self.update_sentence(qmatch[1],a_body,a_comment)
    else
      raise "Sentence Identifier Missing"
    end
  end
  
  def update_sentence(a_id,a_body,a_comment)
    begin
      s = REXML::Document.new(a_body).root
      t = REXML::Document.new(self.xml_content)
      old = REXML::XPath.first(t,"/treebank/sentence[@id=#{a_id}]")
      if (old.nil?)
        raise "Invalid Sentence Identifier"
      end
      REXML::XPath.each(old,"word") { |w|
         old.delete_element(w) 
      }
      REXML::XPath.each(s,"word") { |w|
         old.add_element(w.clone) 
      }
    rescue Exception => e
      raise e
    end
    updated = toXmlString t
    self.set_xml_content(updated, :comment => a_comment)
    return updated
  end
  
  # Place any actions you always want to perform on  identifier content prior to it being committed in this method
  # - *Args*  :
  #   - +content+ -> TreebankCiteIdentifier XML as string
  def before_commit(content)
    TreebankCiteIdentifier.preprocess(content)
  end
  
  # Applies the preprocess XSLT to 'content'
  # - *Args*  :
  #   - +content+ -> XML as string
  # - *Returns* :
  #   - modified 'content'
  def self.preprocess(content)
    # TODO verify against correct schema for format
      return content  
  end  

  ## method which checks the cite object for an initialization  value
  def is_match?(a_value) 
    has_any_targets = false
   # for a treebank annotation, the match will be on the target urns
    a_value.each do | uri |
      begin
        urn_value = uri.match(/^https?:.*?(urn:cts:.*)$/).captures[0]
        urn_obj = CTS::CTSLib.urnObj(urn_value)
      rescue Exception => e
        # if we get an exception it might be an invalid urn or it might be something that
        # isn't a urn
        if (! uri =~ /urn:cts:/)
          # not a cts urn, just assume we have to create a new template
          raise "Not a URN"
        else 
          # otherwise raise an error
          raise e
        end
      end
      # TODO need a way to test target uris which aren't CTS urns
      unless (urn_obj.nil?)
        t = REXML::Document.new(self.xml_content).root
        passage = urn_obj.getPassage(100)
        work = urn_obj.getUrnWithoutPassage()
        passage.split(/-/).each do | p |
          REXML::XPath.each(t,"sentence[@document_id='#{work}']") do | s |
            unless (s.attributes['subdoc'].match(/^#{p}(\.|$)/).nil?)
              has_any_targets = true
              break
            end
          end
        end  
      end
    end
    # TODO compare the requested text urn against the text urns in this treebank document
    return has_any_targets
  end
  
  # preview 
  # outputs the sentence list
  def preview parameters = {}, xsl = nil
    parameters[:s] ||= 1
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(self.xml_content),
      JRubyXML.stream_from_file(File.join(RAILS_ROOT,
        xsl ? xsl : %w{data xslt cite treebanklist.xsl})),
        :doc_id => self.id,
        :s => parameters[:s],
        :max => 20, # TODO - make max sentences configurable
        :tool_url => Tools::Manager.tool_config('treebank_editor')[:view_url])  
 end
  
  # edit 
  # outputs the sentence list with sentences linked to editor
  def edit parameters = {}, xsl = nil
    parameters[:s] ||= 1
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(self.xml_content),
      JRubyXML.stream_from_file(File.join(RAILS_ROOT,
        xsl ? xsl : %w{data xslt cite treebanklist.xsl})),
        :doc_id => self.id,
        :max => 20, # TODO - make max sentences configurable
        :s => parameters[:s],
        :tool_url => Tools::Manager.tool_config('treebank_editor')[:edit_url])  
  end
  
  
  # need to update the uris to reflect the new name
  def after_rename(options = {})
    annot_uri = SITE_CITE_COLLECTION_NAMESPACE + "/" + self.urn_attribute
    # TODO update uri 
    self.set_xml_content(updated, :comment => 'Update uris to reflect new identifier')
  end
end