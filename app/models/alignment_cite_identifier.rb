class AlignmentCiteIdentifier < CiteIdentifier   
  include OacHelper

  FRIENDLY_NAME = "Alignment Annotation"
  PATH_PREFIX="CITE_ALIGNMENT_XML"
  FILE_TYPE="xml"

  XML_VALIDATOR = JRubyXML::AlpheiosAlignmentValidator
  
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
  
  # @see CiteIdentifier.fragment
  def fragment(a_query)
    qmatch = /^s=(\d+)$/.match(a_query)
    if (qmatch.nil?)
      raise Exception.new("Invalid request - no sentence specified in #{a_query}")
    end
    return sentence(qmatch[1])
  end
  
  def patch(a_agent,a_query,a_body,a_comment)
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
  
  # need to update the uris to reflect the new name
  def after_rename(options = {})
    # TODO 
  end
  
  
end
