module CTS
  require 'jruby_xml'
  require 'net/http'
  require "uri"
  
  
  CTS_JAR_PATH = File.join(File.dirname(__FILE__), *%w"java cts3.jar")  
  GROOVY_JAR_PATH = File.join(File.dirname(__FILE__), *%w"java groovy-all-1.6.2.jar")  
  CTS_NAMESPACE = "http://chs.harvard.edu/xmlns/cts3/ti"
  
  module CTSLib
    class << self

      def get_config(a_key)
        unless defined? @config
          @config = YAML::load(ERB.new(File.new(File.join(Rails.root, %w{config cts.yml})).read).result)[Rails.env]
        end
        @config[a_key]
      end
      
      # method which returns a CtsUrn object from the java chs cts3 library
      def urnObj(a_urn)
        # HACK to make new style subrefs work with old library
        # TODO remove when cts.jar is upgraded to 4.0
        a_urn = a_urn.sub('@','#')
        if(RUBY_PLATFORM == 'java')
          require 'java'
          require CTS_JAR_PATH
          require GROOVY_JAR_PATH
          java_import("edu.harvard.chs.cts3.CtsUrn") { |pkg, name| "J" + name }
          urn = JCtsUrn.new(a_urn)
        else
          require 'rubygems'
          require 'rjb'
          Rjb::load(classpath = ".:#{CTS_JAR_PATH}:#{GROOVY_JAR_PATH}", jvmargs=[])
          cts_urn_class = Rjb::import('edu.harvard.chs.cts3.CtsUrn')
          urn = cts_urn_class.new(a_urn)
        end
        return urn
      end
      
      # TODO - use CTS Library for this once we are using the right version
      
      def get_subref(a_urn)
        if a_urn =~ /^.*[\#@]([^\#@]+)$/
          "#{$1}"
        else 
          nil 
        end
      end

      # compares two cts urn objects to see if the match
      # at the requested level (textgroup, work or version)
      def is_cts_match?(a_urn,b_urn,a_match_level)
        is_cts_match = false
        if a_match_level == 'textgroup' && 
          is_cts_match = (a_urn.getTextGroup == b_urn.getTextGroup) 
        elsif a_match_level == 'work'
          is_cts_match = (a_urn.getTextGroup == b_urn.getTextGroup) && (a_urn.getWork == b_urn.getWork)
        else
          is_cts_match = (a_urn.getTextGroup == b_urn.getTextGroup) && (a_urn.getWork == b_urn.getWork) && (a_urn.getVersion == b_urn.getVersion)
        end
        is_cts_match
      end 

      # get a pub type for a urn from the parent inventory
      def versionTypeForUrn(a_inventory,a_urn)
        urn = urnObj(a_urn)
        response = Net::HTTP.get_response(
          URI.parse(self.getInventoryUrl(a_inventory) + "&request=GetCapabilities"))
        results = JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(response.body.force_encoding("UTF-8")),
          JRubyXML.stream_from_file(File.join(Rails.root,
              %w{data xslt cts extract_reply.xsl})))
        xml = REXML::Document.new(results)
        xpath = "//ti:textgroup[@projid='#{urn.getTextGroup(true)}']/ti:work[@projid='#{urn.getWork(true)}']/*[@projid='#{urn.getVersion(true)}']"
        node = REXML::XPath.first(xml, xpath,{ "ti"=> CTS_NAMESPACE })
        nodeName = nil
        unless (node.nil?)
          nodeName = node.local_name()
        end
        return nodeName
      end
      
      # method which inserts the publication type (i.e. edition or translation) into the path of a CTS urn
      def pathForUrn(a_urn,a_pubtype) 
        path_parts = a_urn.sub(/urn:cts:/,'').split(':')
        cite_parts = path_parts[1].split(/\./)
        passage = path_parts[2]
        last_part = cite_parts.length() - 1
        document_path_parts = []
        # SoSOL CTS identifier path looks like NS/authornum.worknum/pubtype/editionnum.exemplarnum/passage
        # NS
        document_path_parts << path_parts[0]
        # textgroup and work
        document_path_parts << cite_parts[0..1].join(".")
        # edition path insert
        document_path_parts << a_pubtype
        # edition and exemplar
        document_path_parts << cite_parts[2..last_part].join(".")
        # only include the passage if we have one 
        unless passage.nil?
          document_path_parts << passage
        end
        return document_path_parts.join('/')        
      end
      
      def workTitleForUrn(doc,a_urn)
        urn = urnObj(a_urn)
        #response = Net::HTTP.get_response(
        #  URI.parse(self.getInventoryUrl(a_inventory) + "&request=GetCapabilities"))
        results = JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(doc),
          JRubyXML.stream_from_file(File.join(Rails.root,
              %w{data xslt cts work_title.xsl})), 
              :textgroup => urn.getTextGroup(true), :work => urn.getWork(true))
        return results
      end
      
      def versionTitleForUrn(a_inventory,a_urn)
        # make sure we have the urn:cts prefix
        unless (a_urn =~ /^urn:cts:/) 
          a_urn = "urn:cts:#{a_urn}"
        end
        urn = urnObj(a_urn)
        response = Net::HTTP.get_response(
          URI.parse(self.getInventoryUrl(a_inventory) + "&request=GetCapabilities"))
        results = JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(response.body.force_encoding("UTF-8")),
          JRubyXML.stream_from_file(File.join(Rails.root,
              %w{data xslt cts version_title.xsl})), 
              :textgroup => urn.getTextGroup(true), :work => urn.getWork(true), :version => urn.getVersion(true) )
        return results
      end
      
      def getInventory(a_inventory)
         response = Net::HTTP.get_response(
            URI.parse(self.getInventoryUrl(a_inventory) + "&request=GetCapabilities"))
         results = JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(response.body.force_encoding("UTF-8")),
          JRubyXML.stream_from_file(File.join(Rails.root,
              %w{data xslt cts extract_reply.xsl})))
         return results
      end
      
      def isCTSIdentifier(a_identifier)
        components = a_identifier.split('/')
        return getInventoriesHash().has_key?(components[0])
      end
      
      def getInventoryUrl(a_inventory)
        # first check the internal repos
        if (getExternalCTSHash().has_key?(a_inventory))
          @external_cts.fetch(a_inventory).fetch('api')
        elsif (getInventoriesHash().has_key?(a_inventory))
          get_config(:cts_api_endpoint) + "inv=" + a_inventory   
        else
          raise "#{a_inventory} CTS Repository is not registered."
        end
      end
            
      def getExternalCTSRepos()
        getExternalCTSHash()
        repos = Hash.new
        keys = Hash.new
        urispaces = Hash.new
        @external_cts.keys.each do |a_key|
          keys[a_key] = @external_cts.fetch(a_key).fetch('urispace')
          urispaces[@external_cts.fetch(a_key).fetch('urispace')] = a_key
        end
        repos['keys'] = keys
        repos['urispaces'] = urispaces
        return repos
      end
      
      def getExternalCTSHash()
        unless defined? @external_cts
          @external_cts = Hash.new
          endpoints = get_config(:external_cts_api_endpoints)
          if defined?(endpoints)
            endpoints.split(',').each do |entry|
              info = entry.split('|')
              repo_info = Hash.new
              repo_info['api'] = info[1]
              repo_info['urispace'] = info[2]
              @external_cts[info[0]] = repo_info
            end
          end
        end
        return @external_cts
      end
      
      def getInventoriesHash()
        unless defined? @inventories_hash
          @inventories_hash = Hash.new
          endpoints = get_config(:cts_inventories)
          if defined?(endpoints)
            endpoints.split(',').each do |entry|
              info = entry.split('|')
              @inventories_hash[info[0]] = info[1]
            end
          end
        end
        return @inventories_hash
      end
      
      def getIdentifierClassName(a_identifier)
          getInventoriesHash()
          components = a_identifier.split('/')
          if (@inventories_hash.has_key?(components[0]))
            pub_type = ''
            if (components[5])
              pub_type='Citation'
            elsif (components[3] == 'translation')
              pub_type='Trans'  
            end
            id_type = @inventories_hash.fetch(components[0]) + pub_type + "CTSIdentifier"
            return id_type
          end  
          return nil
      end
      
      def getIdentifierKey(a_identifier)
          getInventoriesHash()
          components = a_identifier.split('/')
          id_type = nil
          if (components.last == 'annotations')
            id_type = 'OACIdentifier'
          elsif (components[3] == 'textinventory')
            id_type = 'CTSInventoryIdentifier'
          elsif (@inventories_hash.has_key?(components[0]))
            pub_type = ''
            if (components[5])
              pub_type='Passage'
            elsif (components[3] == 'translation')
              pub_type='Trans'  
            end
            id_type = @inventories_hash.fetch(components[0]) + pub_type + "CTSIdentifier"
          end  
          unless id_type.nil?
            return id_type.constantize::IDENTIFIER_NAMESPACE
          end
          return nil
      end
       
      def getEditionUrns(a_inventory)
        Rails.logger.info self.getInventoryUrl(a_inventory) + "&request=GetCapabilities"
        response = Net::HTTP.get_response(
          URI.parse(self.getInventoryUrl(a_inventory) + "&request=GetCapabilities"))
        results = JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(response.body.force_encoding("UTF-8")),
          JRubyXML.stream_from_file(File.join(Rails.root,
              %w{data xslt cts inventory_to_json.xsl})))
        return results
      end
      
      def getTranslationUrns(a_inventory,a_urn)
        urn = urnObj(a_urn)
        response = Net::HTTP.get_response(
          URI.parse(self.getInventoryUrl(a_inventory) + "&request=GetCapabilities"))
        results = JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(response.body.force_encoding("UTF-8")),
          JRubyXML.stream_from_file(File.join(Rails.root,
              %w{data xslt cts inventory_trans_to_json.xsl})), 
              :e_textgroup => urn.getTextGroup(true), :e_work => urn.getWork(true), :e_expression => 'translation')
        return results
      end
      
      def proxyGetCapabilities(a_inventory)
         response = Net::HTTP.get_response(
          URI.parse(self.getInventoryUrl(a_inventory) + "&request=GetCapabilities"))
        return response.body
      end
      
      def proxyGetValidReff(a_inventory,a_urn,a_level)  
        uri = URI.parse(get_config(:cts_api_endpoint) + "request=GetValidReff&inv=#{a_inventory}&urn=#{a_urn}&level=#{a_level}")
        response = Net::HTTP.start(uri.host, uri.port) do |http|
          http.send_request('GET',uri.request_uri)
        end
        if (response.code == '200')
           results = JRubyXML.apply_xsl_transform(
                   JRubyXML.stream_from_string(response.body.force_encoding("UTF-8")),
                   JRubyXML.stream_from_file(File.join(Rails.root,
                   %w{data xslt cts validreff_urns.xsl})))  
        else
           Rails.logger.error("Error response from #{uri}")
           nil
        end
      end
      
      def getValidReffFromRepo(a_uuid,a_inventory,a_document,a_urn,a_level)
        begin
          # post inventory and get path for file put 
          uri = URI.parse(get_config(:cts_extension_api_endpoint) + "request=CreateCitableText&xuuid=#{a_uuid}&urn=#{a_urn}")
          response = Net::HTTP.start(uri.host, uri.port) do |http|
            headers = {'Content-Type' => 'text/xml; charset=utf-8'}
            http.send_request('POST',uri.request_uri,a_inventory,headers)
          end # end http put of inventory
          if (response.code == '200')
            path = JRubyXML.apply_xsl_transform(
              JRubyXML.stream_from_string(response.body.force_encoding("UTF-8")),
              JRubyXML.stream_from_file(File.join(Rails.root,
              %w{data xslt cts extract_reply_text.xsl})))  
            if (path != '')
              # inventory put succeeded, now put the document itself  
              pathUri = URI.parse(get_config(:cts_extension_api_put_endpoint) + path)
              put_response = Net::HTTP.start(pathUri.host, pathUri.port) do |http|
                headers = {'Content-Type' => 'text/xml; charset=utf-8'}
                http.send_request('PUT', pathUri.request_uri, a_document,headers)      
              end # end put of document
              if (put_response.code == '201')
                # request valid reffs
                rurl = URI.parse(get_config(:cts_api_endpoint) + "request=GetValidReff&inv=#{a_uuid}&urn=#{a_urn}&level=#{a_level}")
                refs_response = Net::HTTP.start(rurl.host, rurl.port) do |http|
                  http.send_request('GET', rurl.request_uri)
                end # end valid reffs request
                if (refs_response.code == '200')
                  JRubyXML.apply_xsl_transform(
                    JRubyXML.stream_from_string(refs_response.body.force_encoding("UTF-8")),
                    JRubyXML.stream_from_file(File.join(Rails.root,
                    %w{data xslt cts validreff_urns.xsl})))  
                else
                  Rails.logger.error("Error response from #{uri}")
                  nil
                end # end  valid reffs
              else 
                Rails.logger.error("Error response from #{pathUri}")
              end # end  put of text
            else
              Rails.logger.error("No path to inventory")
            end # end test on path to inventory
          else 
            Rails.logger.error("Error response from #{uri}")  
          end # end put of inventory
        ensure
          # cleanup
          rurl = URI.parse( get_config(:cts_extension_api_endpoint) + "request=DeleteCitableText&urn=#{a_urn}&xuuid=#{a_uuid}") 
          Net::HTTP.get_response(rurl)
        end
      end
      
      def getPassage(a_id,a_urn,a_checkExists)
        passage = nil
        urn_no_subref = a_urn.sub(/[\#@][^\#@]+$/,'')
        if (a_id =~ /^\d+$/)
          documentIdentifier = Identifier.find(a_id)
          # look to see if we have extracted this citation already and are editing it
          matches = a_checkExists ? check_for_citation(documentIdentifier,urn_no_subref) : []
          inventory_code = documentIdentifier.related_inventory.name.split('/')[0]
          if (getExternalCTSHash().has_key?(inventory_code))
            passage = _proxyGetPassage(inventory_code,urn_no_subref)
          else
            inventory = documentIdentifier.related_inventory.xml_content
            uuid = documentIdentifier.publication.id.to_s + a_urn.gsub(':','_') + '_proxyreq'
            content = matches.length > 0 ? matches[0].content : documentIdentifier.content
            passage = _getPassageFromRepo(inventory,content,urn_no_subref,uuid)
          end
        else
          passage = _proxyGetPassage(a_id,urn_no_subref)
        end      
        JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(passage),
          JRubyXML.stream_from_file(File.join(Rails.root,
          %w{data xslt cts extract_getpassage_reply.xsl})))  
      end
            
      def _getPassageFromRepo(inventory,a_document,a_urn,a_uuid)
          passage = ''
          begin
            # post inventory and get path for file put 
            # TODO CTS extensions should be at different base URI (e.g. CTS-X)
             uri = URI.parse(get_config(:cts_extension_api_endpoint) + "request=CreateCitableText&xuuid=#{a_uuid}&urn=#{a_urn}")
             response = Net::HTTP.start(uri.host, uri.port) do |http|
                  headers = {'Content-Type' => 'text/xml; charset=utf-8'}
                  http.send_request('POST',uri.request_uri,inventory,headers)
             end
             if (response.code == '200')
              path = JRubyXML.apply_xsl_transform(
                     JRubyXML.stream_from_string(response.body.force_encoding("UTF-8")),
                     JRubyXML.stream_from_file(File.join(Rails.root,
                     %w{data xslt cts extract_reply_text.xsl})))  
              if (path != '')
                # inventory put succeeded, now put the document itself  
                pathUri = URI.parse(get_config(:cts_extension_api_put_endpoint) + path)
                put_response = Net::HTTP.start(pathUri.host, pathUri.port) do |http|
                  headers = {'Content-Type' => 'text/xml; charset=utf-8'}
                  http.send_request('PUT', pathUri.request_uri, a_document,
  headers)      
                end # end Net::HTTP.start
                if (put_response.code == '201')
                # request passage
                  rurl = URI.parse(get_config(:cts_api_endpoint) + "request=GetPassage&inv=#{a_uuid}&urn=#{a_urn}")
                  psg_response = Net::HTTP.start(rurl.host, rurl.port) do |http|
                    http.send_request('GET', rurl.request_uri)
                  end # end Net::HTTP.start
                  if (psg_response.code == '200')
                    return psg_response.body.force_encoding("UTF-8")
                  else 
                   raise "Passage request failed #{psg_response.code} #{psg_response.msg} #{psg_response.body}"
                  end # end test on GetPassagePlus response code
                else 
                  raise "Put text failed #{put_response.code} #{put_response.msg} #{put_response.body} document #{a_document}"
                end # end test on text Put request
              else
                  raise "no path for put"
              end  # end test on path retrieved from CreateCitableText response          
             else 
              raise "Inventory post failed #{response.code} #{response.msg} #{response.body}"
            end # end test on GetCitationText response code
        ensure
          # cleanup
          rurl = URI.parse(get_config(:cts_extension_api_endpoint) + "request=DeleteCitableText&urn=#{a_urn}&xuuid=#{a_uuid}") 
          Net::HTTP.get_response(rurl)
        end
      end
      
      def _proxyGetPassage(a_inventory,a_urn)
        urn_no_subref = a_urn.sub(/[\#@][^\#@]+$/,'')
        response = Net::HTTP.get_response(URI.parse(self.getInventoryUrl(a_inventory) + 
          "&request=GetPassage&urn=#{urn_no_subref}"))
        return response.body.force_encoding("UTF-8")
      end
      
      def proxyUpdatePassage(a_psg,a_inventory,a_document,a_urn,a_uuid)
        Rails.logger.info("In proxyUpdatePassage with #{a_psg}, #{a_inventory}")

        begin
          # load inventory  -> POST inventory -> returns unique identifier for inventory
          uri = URI.parse(get_config(:cts_extension_api_endpoint) + "request=CreateCitableText&xuuid=#{a_uuid}&urn=#{a_urn}")
          response = Net::HTTP.start(uri.host, uri.port) do |http|
            headers = {'Content-Type' => 'text/xml; charset=utf-8'}
            http.send_request('POST',uri.request_uri,a_inventory,headers)
          end
          # load document -> POST document
          if (response.code == '200')
            Rails.logger.info("Inventory put ok")
            path = JRubyXML.apply_xsl_transform(
              JRubyXML.stream_from_string(response.body.force_encoding("UTF-8")),
              JRubyXML.stream_from_file(File.join(Rails.root,
              %w{data xslt cts extract_reply_text.xsl})))  
            if (path != '')
              pathUri = URI.parse(get_config(:cts_extension_api_put_endpoint) + path)
              put_response = Net::HTTP.start(pathUri.host, pathUri.port) do |http|
                headers = {'Content-Type' => 'text/xml; charset=utf-8'}
                http.send_request('PUT', pathUri.request_uri, a_document,headers)      
              end
              if (put_response.code == '201')
                Rails.logger.info("Document put ok")
                # put passage
                rurl = URI.parse(get_config(:cts_extension_api_endpoint) + "request=UpdatePassage&inv=#{a_uuid}&urn=#{a_urn}") 
                psg_response = Net::HTTP.start(rurl.host, rurl.port) do |http|
                  headers = {'Content-Type' => 'text/xml; charset=utf-8'}
                  http.send_request('POST',rurl.request_uri,a_psg,headers)
                end
                if (psg_response.code == '200')
                  # now we return the updated document
                  Rails.logger.info("Passage put ok #{psg_response.body}")
                  updated_text = JRubyXML.apply_xsl_transform(
                    JRubyXML.stream_from_string(psg_response.body.force_encoding("UTF-8")),
                    JRubyXML.stream_from_file(File.join(Rails.root,
                    %w{data xslt cts extract_updatepassage_reply.xsl})))
                    # if the parsed response doesn't include the updated text 
                    # then raise an error so that we don't overwrite the file with blank data
                    if (updated_text == '' )
                      raise "Update failed: #{psg_response.body}"
                    end 
                    Rails.logger.info("Returning #{updated_text}")
                    return updated_text
                else
                  raise "Passage request failed #{psg_response.code} #{psg_response.msg}>"
                end # psg_response
              else
                raise "Put text failed #{put_response.code} #{put_response.msg}"
              end # put_response
            else 
              raise "No path for put"
            end # put_path          
         else # end post inventory
          raise "Inventory post to #{uri} failed #{response.code} #{response.msg} #{response.body}" 
         end
       rescue Exception => a_e
         raise "Exception in proxyUpdatePassage with #{a_psg}, #{a_inventory}"
       ensure
        # cleanup
        rurl = URI.parse(get_config(:cts_extension_api_endpoint) + "request=DeleteCitableText&urn=#{a_urn}&xuuid=#{a_uuid}") 
        Net::HTTP.get_response(rurl)
        end
      end
      
      def get_catalog_url(a_identifier) 
        # TODO fix catalog to support full, escaped url
        # for POC just use the work and edition
        searchid = a_identifier.to_urn_components[0] + "." + a_identifier.to_urn_components[1]
        return get_config(:catalog_search) + searchid
      end
      
       # Get the list of creatable identifiers for the supplied urn
      # @param {String} a_urn
      def get_creatable_identifiers(a_urn)
        
      end
      
      def check_for_citation(documentIdentifier,urn_no_subref)
        # look to see if we have extracted this citation already and are editing it
          matches = []
          for psgid in documentIdentifier.publication.identifiers do 
            if (psgid.kind_of?(CitationCTSIdentifier))
              if (psgid.urn_attribute == urn_no_subref || 
                  urn_no_subref =~ /^#{Regexp.quote(psgid.urn_attribute)}\./)

                # we want the citation cts identifier if its urn is an exact
                # match OR if its urn is the parent of the requested citation
                matches << psgid 
              end # end test on urn
            end # end test on citation
          end # end loop through identifiers in this documents publication
          return matches 
      end
      
      # a_inv will either be a SoSOL document identifier or the name of the inventory
      def get_tokenized_passage(a_inv, a_urn,a_tags=[])
		    lang = nil
        documentIdentifier = nil
        tokenizer_url = nil   
        passage_url = nil
        temp_uuid = nil
        urn_no_subref = a_urn.sub(/[\#@][^\#@]+$/,'')
        
        if (!a_inv.nil? && a_inv =~ /^\d+$/)
          documentIdentifier = Identifier.find(a_inv)
          matches = check_for_citation(documentIdentifier,urn_no_subref)
          lang = documentIdentifier.lang
          inventory_code = documentIdentifier.related_inventory.name.split('/')[0]
        else
          inventory_code = a_inv
        end
        Rails.logger.info("get_tokenized_passage for #{a_inv} = #{inventory_code}")
        
        tokenizer = Tools::Manager.link_to('cts_tokenizer',lang,:tokenize,nil)
        if (tokenizer.nil?)
          tokenizer = Tools::Manager.link_to('cts_tokenizer',:default,:tokenize,nil)
        end
        tokenizer_url = tokenizer[:href] 
        
      
        begin
        
          # if we don't have an inventory identifier, and the urn is a url
          # just pass it as-is to the tokenizer
          if (a_inv.nil? && a_urn =~ /^http/)
            Rails.logger.debug("Setting passage url to #{a_urn}")
            passage_url = urn_no_subref
          elsif (getExternalCTSHash().has_key?(inventory_code))
            passage_url = getInventoryUrl(inventory_code) + "&request=GetPassage&urn=#{urn_no_subref}"
          else
             proxy_urn = urn_no_subref.gsub(':','_')
            inventory = documentIdentifier.related_inventory.xml_content
            temp_uuid = documentIdentifier.publication.id.to_s + proxy_urn + '_proxyreq'
            # post inventory and get path for file put 
            uri = URI.parse(get_config(:cts_extension_api_endpoint) + "request=CreateCitableText&xuuid=#{temp_uuid}&urn=#{urn_no_subref}")
            response = Net::HTTP.start(uri.host, uri.port) do |http|
              headers = {'Content-Type' => 'text/xml; charset=utf-8'}
              http.send_request('POST',uri.request_uri,inventory,headers)
            end
            if (response.code == '200')
              path = JRubyXML.apply_xsl_transform(
                JRubyXML.stream_from_string(response.body.force_encoding("UTF-8")),
                JRubyXML.stream_from_file(File.join(Rails.root,
                %w{data xslt cts extract_reply_text.xsl})))  
              if (path != '')
                # inventory put succeeded, now put the document itself  
                pathUri = URI.parse(get_config(:cts_extension_api_put_endpoint) + path)
                put_response = Net::HTTP.start(pathUri.host, pathUri.port) do |http|
                  headers = {'Content-Type' => 'text/xml; charset=utf-8'}
                  content = matches.length > 0 ? matches[0].content : documentIdentifier.content
                  http.send_request('PUT', pathUri.request_uri, content,headers)      
                end # end Net::HTTP.start
                if (put_response.code == '201')
                  passage_url = get_config(:cts_api_endpoint) + "request=GetPassage&inv=#{temp_uuid}&urn=#{urn_no_subref}"
                else 
                  raise "Put text failed #{put_response.code} #{put_response.msg} #{put_response.body}"
                end # end test on text Put request
              else
                raise "no path for put"
              end  # end test on path retrieved from CreateCitableText response          
            else 
                raise "Inventory post failed #{response.code} #{response.msg} #{response.body}"
            end # end test on GetCitationText response code        
          end
        

          # we should have a passage url to send to the tokenizer now        
          # TODO should use placeholders to replace values in the tokenizer_url
          # note also variances in support for [] after parameter name
          tokenizer_url = tokenizer_url + CGI.escape(passage_url)
          a_tags.each do |a_tag| 
            tokenizer_url = tokenizer_url + "&tags=#{a_tag}"
          end
          
          Rails.logger.info("Calling tokenizer at #{tokenizer_url}")
          tok_uri = URI(tokenizer_url)
        
          
          tok_response = Net::HTTP.start(tok_uri.host, tok_uri.port) do |http|
            http.send_request('GET',tok_uri.request_uri)
          end
          if (tok_response.code == '200')
            tok_response.response.body.force_encoding("UTF-8")
          else 
            raise "Failed request to #{tok_uri} : #{tok_response.code} #{tok_response.msg} #{tok_response.body}" 
          end
        
        ensure
          # cleanup
          if (temp_uuid)
            rurl = URI.parse(get_config(:cts_extension_api_endpoint) + "request=DeleteCitableText&urn=#{urn_no_subref}&xuuid=#{temp_uuid}") 
            Net::HTTP.get_response(rurl)
          end
        end
      end

      ##
      # Attempts to use the cite_mapper service to map urns to abbreviations
      # @param a urn string
      # @return the abbreviation or the supplied string (if matched failed)
      def urn_abbr(a_target)
        abbr = a_target
        urn_match = a_target.match(/(urn:cts:.*?)$/)
        unless urn_match
          return abbr
        end
        urn = urn_match.captures[0]
        svc_link = Tools::Manager.link_to('cite_mapper','default',:search)
        unless svc_link
           Rails.logger.debug("No cite_mapper service defined")
          return abbr
        end
        svc_link[:href] += "&#{svc_link[:replace_param]}=#{CGI.escape(urn)}"
        begin
          response = Net::HTTP.get_response(URI.parse(svc_link[:href]))
          unless (response.code == '200')
            Rails.logger.error("Failure response from cite_mapper #{response.code}")
            return abbr
          end
          resp = JSON.parse(response.body) 
          abbr = [resp['author'],resp['work'],resp['edition'],resp['section']].compact.reject{|i| i==''}.join(' ')
        rescue Exception => e
         Rails.logger.error("Unable to map urn to abbreviation at #{svc_link[:href]}")
         Rails.logger.error(e.backtrace);
        end
      end 

      ##
      # parse, validate and compose things that might contain urns
      # @param uris - hash such as
      #   { 'urn:cts:greekLit:tlg0012.tlg001.perseus-grc1' => { '1.1' => 1, '2.1' => 1},
      #     'http://data.perseus.org/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1' => { '1.1' => 1},
      #     'http://someotherurl.org/abc/def' => {'any old junk' => 1 }
      #   }
      # @param [Boolean] include_nonurns - if true includes non urn keys as is
      # @returns an array of unique valid urns composed of these parts
      def validate_and_parse(uris, include_nonurns=true)
        parsed = []
        uris.keys.each do |u|
          if u =~ /urn:cts:/
            urn_value = u.match(/(urn:cts:.*)$/).captures[0]
            begin
              urn_obj = CTS::CTSLib.urnObj(urn_value)
              textgroup = urn_obj.getTextGroup(true)
              work = urn_obj.getWork(false)
              version = urn_obj.getVersion(false)
              passage = urn_obj.getPassage(100)
            rescue
              # the first thing to fail will be thrown
            end
            # if we can construct at least a textgroup and work it's a validly formatted cts reference
            if  ! urn_obj.nil? && ! textgroup.nil? && ! work.nil?
              urn = "urn:cts:" + textgroup + "." + work
              if ! version.nil?
                urn = urn + "." + version
              end 
              # add the base urn to the topic list
              parsed << urn
              urn_with_passage = nil
              uris[u].keys.each do |subdoc|
                if passage.nil? 
                  urn_with_passage = urn + ":" + subdoc
                else
                  # if we have a passage in the document_id then the subdoc
                  # is probably a lower level citation
                  urn_with_passage = urn + ':' + passage + "." + subdoc
                end
                parsed << urn_with_passage
              end
              # if we weren't passed subdocs, but have a passage, go ahead and add it as is
              if urn_with_passage.nil? && passage
                parsed << urn + ':' + passage 
              end
            end # end test for cts and subdoc
          elsif include_nonurns 
            # unless we exclude non urns just take everything else as-is
            parsed << u
          end # end test for document_id
        end
        return parsed
      end
    end #class
  end #module CTSLib
end #module CTS
