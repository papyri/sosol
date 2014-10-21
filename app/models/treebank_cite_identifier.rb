require 'nokogiri'
require 'cts'

class TreebankCiteIdentifier < CiteIdentifier   
  include OacHelper

  FRIENDLY_NAME = "Treebank Annotation"
  PATH_PREFIX="CITE_TREEBANK_XML"
  FILE_TYPE="tb.xml"
  ANNOTATION_TITLE = "Treebank Annotation"
  TEMPLATE = "template"
  NS_DCAM = "http://purl.org/dc/dcam/"
  NS_TREEBANK = "http://nlp.perseus.tufts.edu/syntax/treebank/1.5"
  NS_RDF = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  DOM_PARSER = 'REXML'


  
  # TODO Validator depends upon treebank format
  XML_VALIDATOR = JRubyXML::PerseusTreebankValidator

  # Get a dom parser for my xml content
  # @return dom parser
  def xml_parser
    XmlHelper::getDomParser(self.xml_content,DOM_PARSER)
  end
  
  # Overrides Identifier#set_content to make sure content is preprocessed first
  # - *Args*  :
  #   - +content+ -> the XML you want committed to the repository
  #   - +options+ -> hash of options to pass to repository (ex. - :comment, :actor)
  # - *Returns* :
  #   - a String of the SHA1 of the commit
  def set_content(content, options = {})
    content = preprocess(content)
    super
  end
  
  def titleize
    title = self.name
    # TODO should say Treebank on Target URI
    begin
      parsed = XmlHelper::parseattributes(self.xml_content,
      {"sentence" => ['document_id','subdoc']})
      f = parsed['sentence'].first()
      l = parsed['sentence'].last()
      if (f)
        urn = f['document_id']
        unless (urn.nil?)
          urn_match = urn.match(/(urn:cts:.*?)$/)
          if (urn_match)
            urn = urn_match.captures[0]
            urnObj = CTS::CTSLib.urnObj(urn)
            begin
              passage = urnObj.getPassage(100)
            rescue
              # okay not to have a passage
            end
            separator = passage.nil? ? ':' : '.'
            from = f['subdoc']
            unless (from.nil?)
              urn = urn + separator + from 
              to = l['subdoc']
              unless (to.nil? || from == to)
                urn = urn + "-#{to}"
              end
            end
          end
          title = "Treebank of #{CTS::CTSLib.urn_abbr(urn)}"
        end 
      end
    rescue Exception => e
        Rails.logger.error("Error parsing title")
        Rails.logger.error(e.backtrace)
    end
    return title
  end
  
  # initialization method for a new version of an existing Annotation Object
  # adds the creator as a top-level annotator and creates/updates the date
  # @param a_content the original content
  # @return the updated content
  def init_version_content(a_content)
    parser = XmlHelper::getDomParser(a_content,DOM_PARSER)
    treebank = parser.parseroot
    parser.all(treebank,"date").each do |d|
      parser.delete_child(treebank,d)
    end
    date = parser.make_text_elem('date',nil,Time.new.inspect)
    parser.insert_before(treebank,"*[1]",date)
    creator_uri = make_annotator_uri
    xpath = "annotator/uri"
    all_annotators = parser.all(treebank, xpath)
    add = true
    all_annotators.each do |ann|
      if  ann == creator_uri
        add = false
      end
    end
    if (add)
      annotator = parser.make_elem("annotator")
      short = parser.make_text_elem("short",nil,self.publication.creator.name)
      persname = parser.make_text_elem("name",nil,self.publication.creator.human_name)
      address = parser.make_text_elem("address",nil,self.publication.creator.email)
      uri = parser.make_text_elem("uri",nil,creator_uri)
      parser.add_child(annotator,short)
      parser.add_child(annotator,persname)
      parser.add_child(annotator,address)
      parser.add_child(annotator,uri)
      parser.insert_before(treebank,"sentence[1]",annotator)
    end
    parser.to_s
  end
  
  # Initializes a treebank template
  # First looks in the repository to see if we already have a template
  # for the requested URN target. If so, we just use that. Otherwise
  # we send a job to the annotation service to create one
  # @param [String] a_value is the initialization value - in this case the target urn 
  def init_content(a_value)
    template = self.content

    if (! a_value.nil? && a_value.length == 1) 
      init_value = a_value[0].to_s
      if (init_value =~ /urn:cts:/)
        urn_value = init_value.match(/^https?:.*?(urn:cts:.*)$/).captures[0]
        begin
          urn_obj = CTS::CTSLib.urnObj(urn_value)
          unless (urn_obj.nil?)
            base_uri = init_value.match(/^(http?:\/\/.*?)\/urn:cts.*$/).captures[0]
            template_path = path_for_target(TEMPLATE,base_uri,urn_obj)
            template = self.publication.repository.get_file_from_branch(template_path, 'master') 
          end
        rescue Exception => e
            raise "Invalid URN: #{e}" 
        end
      elsif (init_value =~ /^https?:/)
        begin
          rurl = URI.parse(init_value)
          response = Net::HTTP.start(rurl.host, rurl.port) do |http|
            http.send_request('GET', rurl.request_uri)
          end # end Net::HTTP.start
          if (response.code == '200')
            if (is_valid_xml?(response.body))
                template = response.body
            else 
                Rails.logger.error("Failed to retrieve file at #{init_value} #{response.code}")
                raise "Supplied URI does not return a valid treebank file"
            end
          else
            raise "Request for template failed #{response.code} #{response.msg} #{response.body}"
          end # end test on response code
        rescue Exception => e
          Rails.logger.error(e.backtrace)
          raise "Invalid treebank content at #{init_value}"
        end
      else 
        # otherwise raise an error
        Rails.logger.error(e.backtrace)
        raise e
      end
    end
    template_init = init_version_content(template)
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
    parser = self.xml_parser
    t = parser.parseroot
    s = parser.first(t,"/treebank/sentence[@id=#{a_id}]")
    parser.to_s(s)
  end
  
  # get descriptive info for a treebank file
  def api_info(urls)
    # TODO eventually this will be customized per user/file - for now return the default
    template_path = File.join(RAILS_ROOT, ['data','templates'],
                              "treebank-desc-#{self.format}.xml.erb")
    template = ERB.new(File.new(template_path).read, nil, '-')

    # we don't use the attribute lookup methods here because they would
    # each parse the document again
    root_atts = XmlHelper::parseattributes(self.xml_content, 
      {'treebank' => ['format','http://www.w3.org/XML/1998/namespace lang','direction'],
       'sentence' => ['document_id']
      } );
    format = root_atts['treebank'][0]['format']
    lang = root_atts['treebank'][0]['http://www.w3.org/XML/1998/namespace lang']
    direction = root_atts['treebank'][0]['direction'].nil? ? 'ltr' : root_atts['treebank'][0]['direction']
    size = root_atts['sentence'].length
    return template.result(binding)
  end
  
  # get the format for the treebank file
  def format()
    XmlHelper::parseattributes(self.xml_content,{"treebank"=>['format']})["treebank"][0]['format']
  end
  
  
  # get the language for the treebank file
  def language()
    XmlHelper::parseattributes(self.xml_content,{"treebank"=>['http://www.w3.org/XML/1998/namespace lang']})["treebank"][0]['http://www.w3.org/XML/1998/namespace lang']
  end
  
  # get the number of sentences in the treebank file
  def size()
    XmlHelper::parseattributes(self.xml_content,{"sentence"=>['document_id']})
  end
  
   # get the direction of text in the treebank file
  def direction(t = nil)
    d = XmlHelper::parseattributes(self.xml_content,{"treebank"=>['direction']})["treebank"][0]['direction']
    return d.nil? ? 'ltr' : d
  end
  
  # api_get responds to a call from the data management api controller
  # @param [String] a_query if not nil, means use the query to 
  #                         return part of the item
  # TODO the query should really be an XPath 
  def api_get(a_query)
    qmatch = /^s=(\d+)$/.match(a_query)
    if (qmatch.nil?)
      return self.xml_content
    else
      return sentence(qmatch[1])
    end
  end

  def self.api_parse_post_for_identifier(a_post)
    dcam = XmlHelper::parseattributes(a_post, {
      "#{NS_DCAM} memberOf" => ["#{NS_RDF} resource"]})
    dcam["#{NS_DCAM} memberOf"][0]["#{NS_RDF} resource"] 
  end
  
  # try to parse an initialization value from posted data
  def self.api_parse_post_for_init(a_post)
    targets(a_post)
  end
  
  def self.api_create(a_publication,a_agent,a_body,a_comment)
    urn = api_parse_post_for_identifier(a_body) 
    unless (urn)
      raise "Unspecified Collection for #{urn}"
    end
    temp_id = self.new(:name => self.next_object_identifier(urn))
    temp_id.publication = a_publication 
    if (! temp_id.collection_exists?)
      raise "Unregistered CITE Collection for #{urn}"
    end
    temp_id.save!
    parser = XmlHelper::getDomParser(a_body,DOM_PARSER)
    oacxml = parser.parseroot 
    treebank = parser.first(oacxml,"//treebank")
    unless (treebank)
        Rails.logger.error("unable to parse treebank from post")
        raise "Unable to parse treebank for post"
    end
    content = parser.to_s(treebank)
    # use set_xml_content to prevent an invalid file from being initialized
    temp_id.set_xml_content(content, :comment => a_comment)
    template_init = temp_id.init_version_content(content)
    temp_id.set_xml_content(template_init, :comment => 'Initializing Content')
    return temp_id
  end
  
  # api_update responds to a call from the data management api controller
  def api_update(a_agent,a_query,a_body,a_comment)
    qmatch = /^s=(\d+)$/.match(a_query)
    if (qmatch && qmatch.size == 2)
      return self.update_sentence(qmatch[1],a_body,a_comment)
    else
      # if no query, assume it's an entire document
      return self.update_document(a_body,a_comment)
    end
  end
 
  def update_document(a_body,a_comment) 
    self.set_xml_content(a_body, :comment => a_comment)
    return self.xml_content
  end

  def update_sentence(a_id,a_body,a_comment)
    begin
      s_parser = XmlHelper::getDomParser(a_body,DOM_PARSER)
      old_parser = self.xml_parser
      new_sentence = s_parser.parseroot
      t = old_parser.parseroot
      old_sentence = old_parser.first(t,"/treebank/sentence[@id=#{a_id}]")
      if (old_sentence.nil?)
        raise "Invalid Sentence Identifier"
      end
      old_parser.all(old_sentence,"word").each { |w|
         s_parser.delete_child(old_sentence,w)
      }
      new_words = s_parser.all(new_sentence,"word")
      # try with namespace (Alpheios used it)
      if (new_words.length == 0)
        new_words = s_parser.all(new_sentence,"tb:word",{'tb' => NS_TREEBANK})
      end
      new_words.each { |w|
         old_parser.add_child_strip_ns(old_sentence,w.clone) 
      }
    rescue Exception => e
      raise e
    end
    updated = old_parser.to_s
    self.set_xml_content(updated, :comment => a_comment)
    return updated
  end
  
  # Place any actions you always want to perform on  identifier content prior to it being committed in this method
  # - *Args*  :
  #   - +content+ -> TreebankCiteIdentifier XML as string
  def before_commit(content)
    self.preprocess(content)
  end
  
  # Applies the preprocess XSLT to 'content'
  # - *Args*  :
  #   - +content+ -> XML as string
  # - *Returns* :
  #   - modified 'content'
  def preprocess(content)
    # autoadjust sentence numbering
    result = JRubyXML.apply_xsl_transform_catch_messages(
      JRubyXML.stream_from_string(content),
      JRubyXML.stream_from_file(File.join(RAILS_ROOT,%w{data xslt cite treebankrenumber.xsl})))  
    # TODO verify against correct schema for format
    if (! result[:messages].nil? && result[:messages].length > 0)
      self[:transform_messages] = result[:messages]
    end
    return result[:content]
  end  
  

  ## method which checks the cite object for an initialization  value
  def is_match?(a_value) 
    has_any_targets = false
    unless (self.xml_content)
      Rails.logger.info("No xml content found in #{self.name}")
      return has_any_targets
    end
    
    my_targets = XmlHelper::parseattributes(self.xml_content, {"sentence" => ['document_id','subdoc']})
    # we have to just return false if we don't have any targets defined
    # in ourself
    if (my_targets['sentence'].length == 0)
      return has_any_targets
    end
    # for a treebank annotation, the match will be on the target urns
    a_value.each do | uri |
      if has_any_targets
         # one match is enough
         break
      end
      urn_match = uri.match(/^.*?(urn:cts:.*)$/)
      if (urn_match.nil?) 
        # not a cts urn, match will just require match on the document_id 
        # only because we don't know how to parse the subdoc from the uri
        match = my_targets['sentence'].select { |s| 
          s['document_id']  == uri 
        }
        if (match.length > 0)
          has_any_targets = true
          break
        end
      else
        urn_value = urn_match.captures[0]
        begin
          urn_obj = CTS::CTSLib.urnObj(urn_value)
        rescue Exception => e
          # if we get an exception it's invalid urn
          # quietly log an error about the invalid urn
          # and fall through to default for no matches
          Rails.logger.error("Fail to parse urn from #{uri}")
          Rails.logger.error(e.backtrace)
        end
        unless (urn_obj.nil?)
          begin
            passage = nil
            begin
              passage = urn_obj.getPassage(100)
            rescue
              Rails.logger.error("unable to parse passage from #{urn_value}")
            end
            # if we don't have a passage the match should be on the work only
            if (passage.nil?)
              matching_work = my_targets['sentence'].select { |s| 
                doc_match = s['document_id'].match(/(urn:cts:.*?)$/)
                doc_match && doc_match.captures[0] == urn_value
              }
              if (matching_work.length > 0) 
                has_any_targets=true
                break
              end
            elsif (passage)
              work = urn_obj.getUrnWithoutPassage()
              passage.split(/-/).each do | p |
                match = my_targets['sentence'].select { |s| 
                  doc_match = s['document_id'].match(/(urn:cts:.*?)$/)
                  subdoc_match = false
                  if (doc_match && doc_match.captures[0] == work)
                    s['subdoc'].split(/-/).each do |s|
                      if (s.match(/^#{p}(\.|$)/))
                        subdoc_match = true;
                        break;
                     end
                    end
                  end 
                  subdoc_match
               }
               if (match.length > 0)
                 has_any_targets = true
                 break
                end
              end 
            else
              # give up for now if we can't parse the cts urn of 
              # either the document or subdoc
            end 
          rescue Exception => e
            # if we can't parse the urn we can't test it 
            # so just assume it's not a match
            Rails.logger.error(e.backtrace)
          end # end transation on passage calculations
        end # end test on non-null urnObj
      end # end test on urn string
    end
    return has_any_targets
  end
  
  def get_editor_agent
    parser = self.xml_parser 
    t = parser.parseroot
    tool = 'arethusa'
    begin
      parser.all(t, "/treebank/annotator/uri").each do |a_agent| 
        tool_uri = a_agent.text
        agent = Tools::Manager.tool_for_agent('treebank_editor',tool_uri)
        unless (agent.nil?)
          tool = agent
          break;
        end
      end
    rescue Exception => a_e
      Rails.logger.error(a_e.backtrace)
    end
    return tool
  end
  
  # preview 
  # outputs the sentence list
  def preview parameters = {}, xsl = nil
    tool = self.get_editor_agent()
    tool_link = Tools::Manager.link_to('treebank_editor',tool,:view,[self])
    parameters[:s] ||= 1
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(content),
      JRubyXML.stream_from_file(File.join(RAILS_ROOT,
        xsl ? xsl : %w{data xslt cite treebanklist.xsl})),
        :title => self.title,
        :doc_id => self.id,
        :s => parameters[:s],
        :max => 50, # TODO - make max sentences configurable
        :target => tool_link[:target],
        :tool_url => tool_link[:href])
 end
  
  # edit 
  # outputs the sentence list with sentences linked to editor
  def edit parameters = {}, xsl = nil
    tool = self.get_editor_agent()
    tool_link = Tools::Manager.link_to('treebank_editor',tool,:edit,[self])
    parameters[:s] ||= 1
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(content),
      JRubyXML.stream_from_file(File.join(RAILS_ROOT,
        xsl ? xsl : %w{data xslt cite treebanklist.xsl})),
        :title => self.title,
        :doc_id => self.id,
        :max => 50, # TODO - make max sentences configurable
        :s => parameters[:s],
        :target => tool_link[:target],
        :tool_url => tool_link[:href])
  end
  
  
  # need to update the uris to reflect the new name
  def after_rename(options = {})
    annot_uri = SITE_CITE_COLLECTION_NAMESPACE + "/" + self.urn_attribute
    # TODO update uri 
    self.set_xml_content(updated, :comment => 'Update uris to reflect new identifier')
  end

  # find files matching this one metting the supplied conditions
  # @conditions matching params
  def matching_files(a_conditions)
    review_files = []
    check_targets = self.class::targets(self.xml_content)
    if (check_targets) 
      pub_files = Publication.find(
        :all, 
        :conditions => a_conditions).collect { |p| 
          p.identifiers.select{|i| 
              i.class == TreebankCiteIdentifier &&
              i.is_match?(check_targets)
          }
      }
      pub_files.each do |f|
        review_files.concat(f)
      end
    end
    review_files
  end

  # parse the supplied content for annotation targets
  # @param [String] content should be a valid treebank document
  def self.targets(content)
    parsed_targets = []
    parsed = XmlHelper::parseattributes(content,
      {"sentence" => ['document_id','subdoc']})
    parsed['sentence'].each do |s|
      document_id = s['document_id']
      subdoc = s['subdoc']
      if (! document_id.nil?)
        full_uri = document_id
        # we only know how to make subdocs part of the uri 
        # if we are dealing with cts urns
        if (document_id =~ /urn:cts:/ && ! subdoc.nil?)
          urn_value = document_id.match(/(urn:cts:.*)$/).captures[0]
          begin
            urn_obj = CTS::CTSLib.urnObj(urn_value)
            passage = urn_obj.getPassage(100)
          rescue
          end
          unless urn_obj.nil?
            if (passage.nil?)
              full_uri = "#{full_uri}:#{subdoc}"
            else
              # if we have a passage in the document_id then the subdoc
              # is probably a lower level citation
              # TODO probably also should check to be sure the subdoc isn't
              # a subref only
              full_uri = "#{full_uri}.#{subdoc}"
            end
          end
        end # end test for cts and subdoc
        parsed_targets << full_uri
      end # end test for document_id
    end
    return parsed_targets.uniq
  end

end
