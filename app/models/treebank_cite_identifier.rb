require 'nokogiri'
require 'faraday_middleware'

require 'cts'

class TreebankCiteIdentifier < CiteIdentifier   
  include OacHelper

  FRIENDLY_NAME = "Treebank Annotation"
  PATH_PREFIX="CITE_TREEBANK_XML"
  FILE_TYPE="tb.xml"

  NS_DCAM = "http://purl.org/dc/dcam/"
  NS_TREEBANK = "http://nlp.perseus.tufts.edu/syntax/treebank/1.5"
  NS_RDF = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  DOM_PARSER = 'REXML'

  # TODO Validator depends upon treebank format
  XML_VALIDATOR = JRubyXML::PerseusTreebankValidator

  ###################################
  # Public Class Method Overrides
  ###################################

  # @overrides Identifier#identifier_from_content
  # Determines the next identifier  for this class
  # Delegates to the CITE PID Provider, supplying
  # the language of the content as a property
  # - *Args* :
  #   - +agent+ -> the source of the content
  #   - +content+ -> the content
  # - *Returns* :
  #   - identifier name and the content
  def self.identifier_from_content(agent,content)
    language = XmlHelper::parseattributes(content,{"treebank"=>['http://www.w3.org/XML/1998/namespace lang']})["treebank"][0]['http://www.w3.org/XML/1998/namespace lang']
    unless (language)
      language = "misc"
    end
    callback = lambda do |u| return self.sequencer(u) end
    id = self.path_for_version_urn(Cite::CiteLib.pid(self.to_s,{'language' => language},callback))
    parser = XmlHelper::getDomParser(content,DOM_PARSER)
    treebank = parser.parseroot
    parser.all(treebank,"date").each do |d|
      parser.delete_child(treebank,d)
    end
    date = parser.make_text_elem('date',nil,Time.new.inspect)
    parser.insert_before(treebank,"*[1]",date)
    # TODO NOW WE SHOULD INSERT THE URN INTO THE CONTENT
    content = parser.to_s

    return id,content
  end

  # @overrides Identifier#next_temporary_identifier
  # Determines the next identifier  for this class
  # Delegates to the CITE PID Provider
  # - *Returns* :
  #   - identifier name
  def self.next_temporary_identifier
    callback = lambda do |u| return self.sequencer(u) end
    # this isn't really used right now, but if we ever want to we need a way to retrieve the language
    # for the urn template
    return self.path_for_version_urn(Cite::CiteLib.pid(self.to_s,{'language' => 'lat'},callback))
  end

  ###################################
  # Public Instance Method Overrides
  ###################################

  # @overrides Identifier#titleize
  # to set title of a treebank from its content
  # calls on external service to map cts urns
  # to their abbreviations
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

  # @overrides Identifier.fragment
  # - *Args* :
  #   - +query+ -> the query string in the format
  #                "s=<sentencenum>"
  # - *Returns: the sentence or nil if not found
  def fragment(query)
    qmatch = /^s=(\d+)$/.match(query)
    if (qmatch.nil?)
      raise Exception.new("Invalid request - no sentence specified in #{query}")
    end
    return sentence(qmatch[1])
  end

  # @overrides Identifier.patch_content
  # - *Args* :
  #   - +a_agent+ -> String URI identifying source of content
  #   - +a_query+ -> the query string in the format
  #                "s=<sentencenum>"
  #   - +a_content+ -> the new content
  #   - +a_comment+ -> a commit comment
  def patch_content(a_agent,a_query,a_content,a_comment)
    qmatch = /^s=(\d+)$/.match(a_query)
    if (qmatch && qmatch.size == 2)
      return self.update_sentence(qmatch[1],a_content,a_comment)
    else
      # if no query, assume it's an entire document
      return self.update_document(a_content,a_comment)
    end
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
    parser = XmlHelper::getDomParser(content,DOM_PARSER)
    begin
      treebank = parser.parseroot
    
      # make sure we have the creator saved as the annotator
      creator_uri = make_annotator_uri
      xpath = "annotator/uri"
      all_annotators = parser.all(treebank, xpath)
      add = true
      all_annotators.each do |ann|
        if  ann.text == creator_uri
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
      content = parser.to_s
      # autoadjust sentence numbering
      result = JRubyXML.apply_xsl_transform_catch_messages(
        JRubyXML.stream_from_string(content),
        JRubyXML.stream_from_file(File.join(Rails.root,%w{data xslt cite treebankrenumber.xsl})))
      # TODO verify against correct schema for format
      if (! result[:messages].nil? && result[:messages].length > 0)
        # we don't want to immediately commit
        # the revised content -- if there were messages
        # we will store it separately to keep the full chain of history
        self[:transform_messages] = result[:messages]
        self[:postcommit] = result[:content]
      else
        content = result[:content]
      end
    rescue Exception => e
      # invalid xml will cause a parser error - it will be
      # caught at a later stage on the commit check against the
      # schema so just log and move on 
      Rails.logger.error("Error parsing #{e}")
    end
    return content
  end

  ############################################################
  # Public TreebankCiteIdentifier Specific Instance Methods
  ############################################################

  # get a sentence
  # - *Args* :
  #  - +a_id+ -> String the sentence id
  # - *Returns* : the sentence
  def sentence(a_id)
    parser = self.xml_parser
    t = parser.parseroot
    s = parser.first(t,"/treebank/sentence[@id=#{a_id}]")
    parser.to_s(s)
  end
  
  # get the editor agent
  # - *Returns* : the editor agent uri
  def get_editor_agent
    # we want to cache this call because (1) it's not likely to change often 
    # and (2) as we may call it in a request that subsequently retrieves the
    # document for display or editing, it causes a redundant fetch from git
    # which is especially costly on large files
    # caching with the publication cache_key ensures that it will be 
    # re-fetched whenever the document changes
    Rails.cache.fetch("#{self.publication.cache_key}/#{self.id}/editor_agent") do
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
      tool
     end
  end

  # checks the treebank file to see if a comment indicates
  # that a gold standard is available and if so returns
  # the review tool configured for the annotation environment
  def get_reviewer_agent
    # we want to cache this call because (1) it's not likely to change often 
    # and (2) as we may call it in a request that subsequently retrieves the
    # document for display or editing, it causes a redundant fetch from git
    # which is especially costly on large files
    # caching with the publication cache_key ensures that it will be 
    # re-fetched whenever the document changes
    Rails.cache.fetch("#{self.publication.cache_key}/#{self.id}/reviewer_agent") do
      parser = self.xml_parser 
      t = parser.parseroot
      tool = nil
      gold = parser.first(t,"/treebank/comment[@class='gold']")
      if gold && gold.text
        begin
          parser.all(t, "/treebank/annotator/uri").each do |a_agent| 
            tool_uri = a_agent.text
            agent = Tools::Manager.tool_for_agent('treebank_reviewer',tool_uri)
            unless (agent.nil?)
              tool = agent
              break;
            end
          end
        rescue Exception => a_e
          Rails.logger.error(a_e.backtrace)
        end
      end
      tool
    end
  end

  # now that we cache data, we need to allow for it to be explicitly cleared as
  # well, although if we used a external cache like memcached it could be handled
  # there
  def clear_cache
    Rails.cache.delete("#{self.publication.cache_key}/#{self.id}/reviewer_agent")
    Rails.cache.delete("#{self.publication.cache_key}/#{self.id}/editor_agent")
    super()
  end

  ###########################
  # PROTOTYPE METHODS
  ###########################

  # find files matching this one metting the supplied conditions
  # @conditions matching params
  def matching_files(a_conditions)
    review_files = []
    check_targets = self.class::targets(self.xml_content)
    # we enforce a hard limit of 50 to prevent the system from dying horribly
    if (check_targets) 
      pub_files = Publication.find(
        :all, 
        :limit => 50,
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

  # Used to prototype export of CITE Annotations as part
  # of a CTS-Centered Research Object Bundle
  def as_ro
    ro = {'aggregates' => [], 'annotations' => []}
    about = []
    aggregates = []
    urns = self.publication.ro_local_aggregates()
    parsed = XmlHelper::parseattributes(content,
      {"sentence" => ['document_id','subdoc','id']})
    last_target = nil
    parsed['sentence'].each do |s|
      document_id = s['document_id']
      subdoc = s['subdoc']
      if (! document_id.nil?)
        full_uri = document_id
        # we only know how to make subdocs part of the uri 
        # if we are dealing with cts urns
        if (document_id =~ /urn:cts:/)
          urn_value = document_id.match(/(urn:cts:.*)$/).captures[0]
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
      end # end test for document_id
    end
    if about.size > 0 
      ro['annotations'] << { 
        "about" => about.uniq,
        'conformsTo' => 'http://data.perseus.org/rdfvocab/treebank', 
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

  ## method which checks to see if the supplied value is
  ## present in the document_id or subdoc attributes of this treebank file
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
            match_level = 'textgroup'
            begin
              ctsMatch = urn_obj.getWork()
              if ! (ctsMatch.nil? || ctsMatch.match(/:null/))
                match_level = 'work'
              end
              ctsMatch = urn_obj.getVersion()
              if ! (ctsMatch.nil? || ctsMatch.match(/:null/))
                match_level = 'version'
              end
            rescue Exception => e
            end
            if (passage.nil?)
              matching_work = my_targets['sentence'].select { |s|
                is_cts_match = false
                doc_match = s['document_id'] && s['document_id'].match(/(urn:cts:.*?)$/)
                if doc_match
                  begin
                    doc_urn = CTS::CTSLib.urnObj(doc_match.captures[0])
                    is_cts_match = CTS::CTSLib.is_cts_match?(urn_obj,doc_urn,match_level)
                  rescue Exception => e
                    # not a valid urn? not a match
                  end
                end
                is_cts_match
              }
              if (matching_work.length > 0)
                has_any_targets=true
                break
              end
            elsif (passage)
              work = urn_obj.getUrnWithoutPassage()
              passage.split(/-/).each do | p |
                match = my_targets['sentence'].select { |s|
                  doc_match = s['document_id'] && s['document_id'].match(/(urn:cts:.*?)$/)
                  subdoc_match = false
                  if (doc_match)
                    begin
                      doc_urn = CTS::CTSLib.urnObj(doc_match.captures[0])
                      is_cts_match = CTS::CTSLib.is_cts_match?(urn_obj,doc_urn,match_level)
                    rescue Exception => e
                      # not a valid urn? not a match
                    end
                    if is_cts_match
                      s['subdoc'].split(/-/).each do |s|
                        if (s.match(/^#{p}(\.|$)/))
                          subdoc_match = true;
                          break;
                       end
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


  # @overrides Identifier#to_remote_path
  # checks for remote path in comments otherwise delegates
  # to super class
  def to_remote_path
    parser = self.xml_parser
    t = parser.parseroot
    path = parser.first(t,"/treebank/comment[@class='remote_path']")
    if path && path.text
      path.text
    else
      super()
    end
  end



  ########################
  # Private Helper Methods
  ########################
  protected
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

    # Get a dom parser for my xml content
    # @return dom parser
    def xml_parser
      XmlHelper::getDomParser(self.xml_content,DOM_PARSER)
    end
end
