class AlignmentCiteIdentifier < CiteIdentifier   
  include OacHelper

  FRIENDLY_NAME = "Alignment Annotation"
  PATH_PREFIX="CITE_ALIGNMENT_XML"
  FILE_TYPE="xml"
  XML_VALIDATOR = JRubyXML::AlpheiosAlignmentValidator
  NS_ALIGN = "http://alpheios.net/namespaces/aligned-text"

  ##################################################
  # Public Instance Method Overrides
  ##################################################

  # @overrides Identifier#titleize to set the title of an alignment identifier
  # from the contents of the file
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
  
  # @overrides Identifier#fragment
  # - *Args* :
  #   - +a_query+ -> String matching "s=<sentencenum>"
  # - *Returns* :
  #   - the matching sentence or nil if not found
  def fragment(a_query)
    qmatch = /^s=(\d+)$/.match(a_query)
    if (qmatch.nil?)
      raise Exception.new("Invalid request - no sentence specified in #{a_query}")
    end
    return sentence(qmatch[1])
  end
  
  # @overrides Identifier#patch_content
  # - *Args* :
  #   - +a_agent+ -> string URI identifying the agent initiating the patch
  #   - +a_query+ -> query for the fragment to be patched in the format
  #                 "s=<sentencenum>"
  #   - +a_content+ -> the new fragment
  #   - +a_comment+ -> an edit comment
  # - *Returns* :
  #   - the updated fragment
  def patch_content(a_agent,a_query,a_content,a_comment)
    qmatch = /^s=(\d+)$/.match(a_query)
    if (qmatch.size == 2)
      return self.update_sentence(qmatch[1],a_content,a_comment)
    else
      raise Exception.new("Sentence Identifier Missing")
    end
  end

  ###########################
  # PROTOTYPE METHODS
  ###########################

  # Used to prototype export of CITE Annotations as part
  # of a CTS-Centered Research Object Bundle
  def as_ro
    ro = {'aggregates' => [], 'annotations' => []}
    about = []
    aggregates = []
    urns = self.publication.ro_local_aggregates()
    t = REXML::Document.new(self.xml_content)
    REXML::XPath.each(t,"/align:aligned-text/align:sentence/align:wds/align:comment[@class='uri']",{"align"=>NS_ALIGN}).each do |comment|
      uri = comment.text
      if (uri =~ /urn:cts:/)
        urn_value = uri.match(/(urn:cts:.*)$/).captures[0]
        begin
          urn_obj = CTS::CTSLib.urnObj(urn_value)
        rescue
        end
      end
      unless urn_obj.nil?
        u = "urn:cts:" + urn_obj.getTextGroup(true) + "." + urn_obj.getWork(false) + "." + urn_obj.getVersion(false)
        if urns[u]
          about << urns[u] 
        else
          about << u
          aggregates << u
        end
      end
    end
    if about.size > 0 
      ro['annotations'] << { 
        "about" => about.uniq,
        'conformsTo' => 'http://svn.code.sf.net/p/alpheios/code/xml_ctl_files/schemas/trunk/aligned-text.xsd',
        'mediatype' => self.mimetype,
        'content' => File.join('annotations',self.download_file_name),
        'createdBy' => { 'name' => self.publication.creator.full_name, 'uri' => self.publication.creator.uri }
      }
      ro['aggregates'] = aggregates.uniq
      return ro
    else 
      return nil
    end
  end
  
  ########################
  # Private Helper Methods
  ########################
  protected
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
      s_parser = XmlHelper::getDomParser(t,'REXML')
      updated = toXmlString t
      self.set_xml_content(updated, :comment => a_comment)
      return updated
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
end
