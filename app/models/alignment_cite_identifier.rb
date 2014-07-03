class AlignmentCiteIdentifier < CiteIdentifier   
  include OacHelper

  FRIENDLY_NAME = "Alignment Annotation"
  PATH_PREFIX="CITE_ALIGNMENT_XML"
  FILE_TYPE="xml"
  ANNOTATION_TITLE = "Alignment Annotation"
  TEMPLATE = "template"
  COLLECTION = "urn:cite:perseus:align"
  
  XML_VALIDATOR = JRubyXML::AlpheiosAlignmentValidator
  
  # TODO move tokenizer functionality out to a separate class
  XML_TOKENIZER = CTS::CTSLib
  
  NS_ALIGN = "http://alpheios.net/namespaces/aligned-text"
  
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
    title = JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(self.content),
      JRubyXML.stream_from_file(File.join(Rails.root, %w{data xslt cite alignment_title.xsl})))
    if (title != '')
      title
    else
      self.name  
    end
  end
  
  def toXmlString xmlObject
    formatter = PrettySsime.new
    formatter.compact = true
    formatter.width = 2**32
    modified_xml_content = ''
    formatter.write xmlObject, modified_xml_content
    modified_xml_content
  end
  
  def init_content(a_value)
    template = nil
    if (a_value.nil? || a_value.length == 0)
      # no-op creates an empty alignment file
      return
    elsif (a_value.length == 1 && a_value.match(/^http/))
      # TODO assume that the init value is the uri to a valid annotation template
      raise "Initialization from annotation template URI Not yet supported"
    elsif (a_value.length == 2)
      # if we have 2 values, assume we were passed uris identifying passages to be aligned
      begin
        urn_value1 = a_value[0].match(/^https?:.*?(urn:cts:.*)$/).captures[0]
        urn_obj1 = CTS::CTSLib.urnObj(urn_value1)
        urn_value2 = a_value[1].match(/^https?:.*?(urn:cts:.*)$/).captures[0]
        urn_obj2 = CTS::CTSLib.urnObj(urn_value2)
        if (! urn_obj1.nil? && ! urn_obj2.nil?)
          base_uri1 = a_value[0].match(/^(http?:\/\/.*?)\/urn:cts.*$/).captures[0]
          base_uri2 = a_value[1].match(/^(http?:\/\/.*?)\/urn:cts.*$/).captures[0]
          template_path = path_for_target(TEMPLATE,{ 'l1base' => base_uri1 , 'l1urn'=> urn_obj1,
                                                        'l2base' => base_uri2, 'l2urn' => urn_obj2})
          template = self.publication.repository.get_file_from_branch(template_path, 'master')
          # try again, flipping the l1/l2 order
          if (template.nil?)
            template_path = path_for_target(TEMPLATE,{ 'l2base' => base_uri1 , 'l2urn'=> urn_obj1,
                                                        'l1base' => base_uri2, 'l1urn' => urn_obj2})
            template = self.publication.repository.get_file_from_branch(template_path, 'master')
          end
        end
      rescue Exception => e
        Rails.logger.error(e)
        # not a cts urn identifier or an invalid one
      end
    end
          # no template - if we have passage subrefs, then let's create one
    if (template.nil?)
        xml_to_insert = [] 
        a_value.each do |a_uri|
            passage_xml = nil
            local_match = a_uri.match(/\/cts\/getpassage\/(.*?)\/([^\/]+)$/)
            token_elem = 'token'
            urn = ''
            if (local_match && local_match.captures.length == 2)
              passage_xml = XML_TOKENIZER.get_tokenized_passage(local_match.captures[0],local_match.captures[1],[token_elem])
              urn = local_match.captures[1]
            else
              passage_xml = XML_TOKENIZER.get_tokenized_passage(nil,a_uri,[token_elem])
            end            
            if (passage_xml)
              sentence_xml =
                JRubyXML.apply_xsl_transform(
                  JRubyXML.stream_from_string(passage_xml),
                  JRubyXML.stream_from_file(File.join(Rails.root,%w{data xslt cite tokens_to_align.xsl })),
                  :e_uri => a_uri, 
                  :e_subref => XML_TOKENIZER.get_subref(urn),
                  :e_tag => token_elem)
                xml_to_insert << sentence_xml
              end
          end # end each value
        if (xml_to_insert.length == 2)
          title_parts = []
          a_value.each do |a_uri|
            if (a_uri =~ /^(http?:\/\/.*?)(urn:cts.*)$/) 
              title_parts << $2
            else
              title_parts << a_uri
            end
          end
          l1doc = REXML::Document.new(xml_to_insert[0]).root
          l2doc = REXML::Document.new(xml_to_insert[1]).root
          l1words = REXML::XPath.first(l1doc,"//align:wds",{"align" => NS_ALIGN})
          l1words.add_attribute('lnum','L1')
          l2words = REXML::XPath.first(l2doc,"//align:wds",{"align" => NS_ALIGN})
          l2words.add_attribute('lnum','L2')

          t_align = REXML::Document.new(self.file_template).root
          t_title = REXML::XPath.first(t_align,"align:comment[@class='title']",{"align"=>NS_ALIGN})
          t_title.text = "Alignment of #{title_parts.join(' and ')}" 
          t_l1 = REXML::XPath.first(t_align,"align:language[@lnum='L1']",{"align"=>NS_ALIGN})
          t_l2 = REXML::XPath.first(t_align,"align:language[@lnum='L2']",{"align"=>NS_ALIGN})

          t_l1.add_attribute("xml:lang",l1doc.attributes['xml:lang'])
          t_l1.add_attribute("dir",l1doc.attributes['dir'])
          t_l2.add_attribute("xml:lang",l2doc.attributes['xml:lang'])
          t_l2.add_attribute("dir",l2doc.attributes['dir'])

          t_sentence = REXML::XPath.first(t_align,"align:sentence",{"align"=>NS_ALIGN})
          t_sentence.add_attribute('document_id',self.name)
          t_sentence.add_element(l1words)
          t_sentence.add_element(l2words)
          template = toXmlString t_align
        end
    end # end if template.nil
      
    # no template - if we have passage subrefs, then let's create one
    if (template.nil?)
        raise "Unable to create template for #{a_value}"    
     end

    template_init = init_version_content(template)
    self.set_xml_content(template_init, :comment => 'Initializing Content')
  end
  
  # Path for treebank file for target text
  # @param [String] a_type (template or data) 
  # @param [Object] object with properties
  #    l1base: [String] uribase for l1
  #    l1urn: [JCtsUrn] urn for l1
  #    l2base: [String] uribase for l2
  #    l2urn: [JCtsUrn] urn for l2
  # @return [String] the repository path
  def path_for_target(a_type,a_params)
    l1uri = a_params.l1base.gsub(/^http?:\/\//, '')
    l2uri = a_params.l2base.gsub(/^http?:\/\//, '')

    parts = []
    #  PATH_PREFIX/type/uri/l1namespace/l1textgroup/l1work/l1version/l1passage/l2namespace/l2textgroup.work.edition.passage.FILE_TYPE
    parts << PATH_PREFIX
    parts << a_type
    parts << l1uri
    l1tgparts = a_params.l1urn.getTextGroup().split(/:/)
    l1work  = a_params.l1urn.getWork(false)
    parts << l1tgparts[0]
    parts << l1tgparts[1]
    parts << l1work
    parts <<  a_params.l1urn.getVersion(false)
    if (a_params.l1urn.passageComponent)
      parts << a_params.l1urn.getPassage(100)
    end
    parts << l2uri
    l2tgparts = a_params.l2urn.getTextGroup().split(/:/)
    file_parts = []
    file_parts << l2tgparts[1]
    file_parts << a_params.l2urn.getWork(false)
    file_parts <<  a_params.l2urn.getVersion(false)
    if (a_params.l1urn.passageComponent)
      file_parts << a_params.l2urn.getPassage(100)
    end
    file_parts << FILE_TYPE
    parts << file_parts.join(".")
    File.join(parts)
  end
  
  # get a sentence
  # @param [String] a_id the sentence id
  # @return [String] the sentence xml 
  def sentence(a_id)
     JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(content),
      JRubyXML.stream_from_file(File.join(Rails.root, %w{data xslt cite alignment_sentence.xsl})),
      :s => a_id)  
  end
  
  # get descriptive info for an alignment file
  def api_info(urls)
    # TODO
  end
    
  # get the number of sentences in the alignment file
  def size
    t = REXML::Document.new(self.xml_content)
    REXML::XPath.match(t,"/align:aligned-text/align:sentence",{"align" => NS_ALIGN}).size.to_s
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
  def api_update(a_agent,a_query,a_body,a_comment)
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
      old = REXML::XPath.first(t,"/align:aligned-text/align:sentence[@id=#{a_id}]",{"align"=>NS_ALIGN})
      if (old.nil?)
        raise "Invalid Sentence Identifier"
      end
      REXML::XPath.each(old,"*") { |w|
         old.delete_element(w) 
      }
      REXML::XPath.each(s,"//align:sentence/*",{"align" => NS_ALIGN}) { |w|
         old.add_element(w.deep_clone) 
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
    self.preprocess(content)
  end
  
  # Applies the preprocess XSLT to 'content'
  # - *Args*  :
  #   - +content+ -> XML as string
  # - *Returns* :
  #   - modified 'content'
  def preprocess(content)
    # autoadjust sentence numbering
    #result = JRubyXML.apply_xsl_transform_catch_messages(
    #  JRubyXML.stream_from_string(content),
    #  JRubyXML.stream_from_file(File.join(Rails.root,%w{data xslt cite alignrenumber.xsl})))  
    ## TODO verify against correct schema for format
    #if (! result[:messages].nil? && result[:messages].length > 0)
    #  self[:transform_messages] = result[:messages]
    #end
    #return result[:content]
    return content
  end  
  

  ## method which checks the cite object for an initialization  value
  def is_match?(a_value) 
    has_any_targets = false
   # check for any alignment that has both sentence uris in it
    matched_targets = []
    a_value.each do | uri |
      t = REXML::Document.new(self.xml_content).root
      REXML::XPath.each(t,"//align:wds/align:comment[@class='uri']",{"align" => NS_ALIGN}) do |c_uri|
        if (c_uri.text == uri)
          matched_targets << c_uri
        end
      end 
    end
    return matched_targets.length == a_value.length
  end
  
  # preview 
  # outputs the sentence list
  def preview parameters = {}, xsl = nil
    parameters[:s] ||= 1
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(content),
      JRubyXML.stream_from_file(File.join(Rails.root,
        xsl ? xsl : %w{data xslt cite alignment_list.xsl})),
        :doc_id => self.id,
        :s => parameters[:s],
        :max => 50, # TODO - make max sentences configurable
        :tool_url => Tools::Manager.tool_config('alignment_editor')[:view_url])  
 end
  
  # edit 
  # outputs the sentence list with sentences linked to editor
  def edit parameters = {}, xsl = nil
    parameters[:s] ||= 1
    JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(content),
      JRubyXML.stream_from_file(File.join(Rails.root,
        xsl ? xsl : %w{data xslt cite alignment_list.xsl})),
        :doc_id => self.id,
        :max => 50, # TODO - make max sentences configurable
        :s => parameters[:s],
        :tool_url => Tools::Manager.tool_config('alignment_editor')[:edit_url])  
  end
  
  
  # need to update the uris to reflect the new name
  def after_rename(options = {})
    # TODO 
  end
  
  
end
