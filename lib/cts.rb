module CTS
  require 'jruby_xml'
  require 'net/http'
  require "uri"
  
  
  CTS_JAR_PATH = File.join(File.dirname(__FILE__), *%w"java cts3.jar")  
  GROOVY_JAR_PATH = File.join(File.dirname(__FILE__), *%w"java groovy-all-1.6.2.jar")  
  CTS_NAMESPACE = "http://chs.harvard.edu/xmlns/cts3/ti"
  EXIST_HELPER_REPO = "#{EXIST_STANDALONE_URL}/exist/rest/db/xq/"
  EXIST_HELPER_REPO_PUT = "#{EXIST_STANDALONE_URL}/exist/rest"
  
  module CTSLib
    class << self
      
      # method which returns a CtsUrn object from the java chs cts3 library
      def urnObj(a_urn)
        # HACK to make new style subrefs work with old library
        # TODO remove when cts.jar is upgraded to 4.0
        a_urn = a_urn.sub('@','#')
        if(RUBY_PLATFORM == 'java')
          require 'java'
          require CTS_JAR_PATH
          require GROOVY_JAR_PATH
          include_class("edu.harvard.chs.cts3.CtsUrn") { |pkg, name| "J" + name }
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
      
      # get a pub type for a urn from the parent inventory
      def versionTypeForUrn(a_inventory,a_urn)
        urn = urnObj(a_urn)
        response = Net::HTTP.get_response(
          URI.parse(self.getInventoryUrl(a_inventory) + "&request=GetCapabilities"))
        results = JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(response.body),
          JRubyXML.stream_from_file(File.join(RAILS_ROOT,
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
        path_parts = a_urn.sub!(/urn:cts:/,'').split(':')
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
          JRubyXML.stream_from_file(File.join(RAILS_ROOT,
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
          JRubyXML.stream_from_string(response.body),
          JRubyXML.stream_from_file(File.join(RAILS_ROOT,
              %w{data xslt cts version_title.xsl})), 
              :textgroup => urn.getTextGroup(true), :work => urn.getWork(true), :version => urn.getVersion(true) )
        return results
      end
      
      def getInventory(a_inventory)
         response = Net::HTTP.get_response(
            URI.parse(self.getInventoryUrl(a_inventory) + "&request=GetCapabilities"))
         results = JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(response.body),
          JRubyXML.stream_from_file(File.join(RAILS_ROOT,
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
          EXIST_HELPER_REPO + 'CTS.xq?inv=' + a_inventory   
        else
          Rails.logger.info(@external_cts.inspect)
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
          EXTERNAL_CTS_REPOS.split(',').each do |entry|
            info = entry.split('|')
            repo_info = Hash.new
            repo_info['api'] = info[1]
            repo_info['urispace'] = info[2]
            @external_cts[info[0]] = repo_info
          end
        end
        return @external_cts
      end
      
      def getInventoriesHash()
        unless defined? @inventories_hash
          @inventories_hash = Hash.new
          SITE_CTS_INVENTORIES.split(',').each do |entry|
            info = entry.split('|')
            @inventories_hash[info[0]] = info[1]
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
        response = Net::HTTP.get_response(
          URI.parse(self.getInventoryUrl(a_inventory) + "&request=GetCapabilities"))
        results = JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(response.body),
          JRubyXML.stream_from_file(File.join(RAILS_ROOT,
              %w{data xslt cts inventory_to_json.xsl})))
        return results
      end
      
      def getTranslationUrns(a_inventory,a_urn)
        urn = urnObj(a_urn)
        response = Net::HTTP.get_response(
          URI.parse(self.getInventoryUrl(a_inventory) + "&request=GetCapabilities"))
        results = JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(response.body),
          JRubyXML.stream_from_file(File.join(RAILS_ROOT,
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
        uri = URI.parse("#{EXIST_HELPER_REPO}CTS.xq?request=GetValidReff&inv=#{a_inventory}&urn=#{a_urn}&level=#{a_level}")
        response = Net::HTTP.start(uri.host, uri.port) do |http|
          http.send_request('GET',uri.request_uri)
        end
        if (response.code == '200')
           results = JRubyXML.apply_xsl_transform(
                   JRubyXML.stream_from_string(response.body),
                   JRubyXML.stream_from_file(File.join(RAILS_ROOT,
                   %w{data xslt cts validreff_urns.xsl})))  
        else
           Rails.logger.error("Error response from #{uri}")
           nil
        end
      end
      
      def getValidReffFromRepo(a_uuid,a_inventory,a_document,a_urn,a_level)
        begin
          # post inventory and get path for file put 
          uri = URI.parse("#{EXIST_HELPER_REPO}CTS-X.xq?request=CreateCitableText&xuuid=#{a_uuid}&urn=#{a_urn}")
          response = Net::HTTP.start(uri.host, uri.port) do |http|
            headers = {'Content-Type' => 'text/xml; charset=utf-8'}
            http.send_request('POST',uri.request_uri,a_inventory,headers)
          end # end http put of inventory
          if (response.code == '200')
            path = JRubyXML.apply_xsl_transform(
              JRubyXML.stream_from_string(response.body),
              JRubyXML.stream_from_file(File.join(RAILS_ROOT,
              %w{data xslt cts extract_reply_text.xsl})))  
            if (path != '')
              # inventory put succeeded, now put the document itself  
              pathUri = URI.parse("#{EXIST_HELPER_REPO_PUT}#{path}")
              put_response = Net::HTTP.start(pathUri.host, pathUri.port) do |http|
                headers = {'Content-Type' => 'text/xml; charset=utf-8'}
                http.send_request('PUT', pathUri.request_uri, a_document,headers)      
              end # end put of document
              if (put_response.code == '201')
                # request valid reffs
                rurl = URI.parse("#{EXIST_HELPER_REPO}CTS.xq?request=GetValidReff&inv=#{a_uuid}&urn=#{a_urn}&level=#{a_level}")
                refs_response = Net::HTTP.start(rurl.host, rurl.port) do |http|
                  http.send_request('GET', rurl.request_uri)
                end # end valid reffs request
                if (refs_response.code == '200')
                  JRubyXML.apply_xsl_transform(
                    JRubyXML.stream_from_string(refs_response.body),
                    JRubyXML.stream_from_file(File.join(RAILS_ROOT,
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
          rurl = URI.parse("#{EXIST_HELPER_REPO}CTS-X.xq?request=DeleteCitableText&urn=#{a_urn}&xuuid=#{a_uuid}") 
          Net::HTTP.get_response(rurl)
        end
      end
      
      def getPassage(a_id,a_urn)
        passage = nil
        urn_no_subref = a_urn.sub(/[\#@][^\#@]+$/,'')
        if (a_id =~ /^\d+$/)
          documentIdentifier = Identifier.find(a_id)
          inventory_code = documentIdentifier.related_inventory.name.split('/')[0]
          if (getExternalCTSHash().has_key?(inventory_code))
            passage = _proxyGetPassage(inventory_code,urn_no_subref)
          else
            inventory = documentIdentifier.related_inventory.xml_content
            uuid = documentIdentifier.publication.id.to_s + a_urn.gsub(':','_') + '_proxyreq'
            passage = _getPassageFromRepo(inventory,documentIdentifier.content,urn_no_subref,uuid)
          end
        else
          passage = _proxyGetPassage(a_id,urn_no_subref)
        end      
        JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(passage),
          JRubyXML.stream_from_file(File.join(RAILS_ROOT,
          %w{data xslt cts extract_getpassage_reply.xsl})))  
      end
            
      def _getPassageFromRepo(inventory,a_document,a_urn,a_uuid)
          passage = ''
          begin
            # post inventory and get path for file put 
            # TODO CTS extensions should be at different base URI (e.g. CTS-X)
             uri = URI.parse("#{EXIST_HELPER_REPO}CTS-X.xq?request=CreateCitableText&xuuid=#{a_uuid}&urn=#{a_urn}")
             response = Net::HTTP.start(uri.host, uri.port) do |http|
                  headers = {'Content-Type' => 'text/xml; charset=utf-8'}
                  http.send_request('POST',uri.request_uri,inventory,headers)
             end
             if (response.code == '200')
              path = JRubyXML.apply_xsl_transform(
                     JRubyXML.stream_from_string(response.body),
                     JRubyXML.stream_from_file(File.join(RAILS_ROOT,
                     %w{data xslt cts extract_reply_text.xsl})))  
              if (path != '')
                # inventory put succeeded, now put the document itself  
                pathUri = URI.parse("#{EXIST_HELPER_REPO_PUT}#{path}")
                put_response = Net::HTTP.start(pathUri.host, pathUri.port) do |http|
                  headers = {'Content-Type' => 'text/xml; charset=utf-8'}
                  http.send_request('PUT', pathUri.request_uri, a_document,
  headers)      
                end # end Net::HTTP.start
                if (put_response.code == '201')
                # request passage
                  rurl = URI.parse("#{EXIST_HELPER_REPO}CTS.xq?request=GetPassage&inv=#{a_uuid}&urn=#{a_urn}")
                  psg_response = Net::HTTP.start(rurl.host, rurl.port) do |http|
                    http.send_request('GET', rurl.request_uri)
                  end # end Net::HTTP.start
                  if (psg_response.code == '200')
                    return psg_response.body
                  else 
                   raise "Passage request failed #{psg_response.code} #{psg_response.msg} #{psg_response.body}"
                  end # end test on GetPassagePlus response code
                else 
                  raise "Put text failed #{put_response.code} #{put_response.msg} #{put_response.body}"
                end # end test on text Put request
              else
                  raise "no path for put"
              end  # end test on path retrieved from CreateCitableText response          
             else 
              raise "Inventory post failed #{response.code} #{response.msg} #{response.body}"
            end # end test on GetCitationText response code
        ensure
          # cleanup
          rurl = URI.parse("#{EXIST_HELPER_REPO}CTS-X.xq?request=DeleteCitableText&urn=#{a_urn}&xuuid=#{a_uuid}") 
          Net::HTTP.get_response(rurl)
        end
      end
      
      def _proxyGetPassage(a_inventory,a_urn)
        urn_no_subref = a_urn.sub(/[\#@][^\#@]+$/,'')
        response = Net::HTTP.get_response(URI.parse(self.getInventoryUrl(a_inventory) + 
          "&request=GetPassage&urn=#{urn_no_subref}"))
        return response.body
      end
      
      def proxyUpdatePassage(a_psg,a_inventory,a_document,a_urn,a_uuid)
        Rails.logger.info("In proxyUpdatePassage with #{a_psg}, #{a_inventory}")

        begin
          # load inventory  -> POST inventory -> returns unique identifier for inventory
          uri = URI.parse("#{EXIST_HELPER_REPO}CTS-X.xq?request=CreateCitableText&xuuid=#{a_uuid}&urn=#{a_urn}")
          response = Net::HTTP.start(uri.host, uri.port) do |http|
            headers = {'Content-Type' => 'text/xml; charset=utf-8'}
            http.send_request('POST',uri.request_uri,a_inventory,headers)
          end
          # load document -> POST document
          if (response.code == '200')
            Rails.logger.info("Inventory put ok")
            path = JRubyXML.apply_xsl_transform(
              JRubyXML.stream_from_string(response.body),
              JRubyXML.stream_from_file(File.join(RAILS_ROOT,
              %w{data xslt cts extract_reply_text.xsl})))  
            if (path != '')
              pathUri = URI.parse("#{EXIST_HELPER_REPO_PUT}#{path}")
              put_response = Net::HTTP.start(pathUri.host, pathUri.port) do |http|
                headers = {'Content-Type' => 'text/xml; charset=utf-8'}
                http.send_request('PUT', pathUri.request_uri, a_document,headers)      
              end
              if (put_response.code == '201')
                Rails.logger.info("Document put ok")
                # put passage
                rurl = URI.parse("#{EXIST_HELPER_REPO}CTS-X.xq?request=UpdatePassage&inv=#{a_uuid}&urn=#{a_urn}") 
                psg_response = Net::HTTP.start(rurl.host, rurl.port) do |http|
                  headers = {'Content-Type' => 'text/xml; charset=utf-8'}
                  http.send_request('POST',rurl.request_uri,a_psg,headers)
                end
                if (psg_response.code == '200')
                  # now we return the updated document
                  Rails.logger.info("Passage put ok #{psg_response.body}")
                  updated_text = JRubyXML.apply_xsl_transform(
                    JRubyXML.stream_from_string(psg_response.body),
                    JRubyXML.stream_from_file(File.join(RAILS_ROOT,
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
        rurl = URI.parse("#{EXIST_HELPER_REPO}CTS-X.xq?request=DeleteCitableText&urn=#{a_urn}&xuuid=#{a_uuid}") 
        Net::HTTP.get_response(rurl)
        end
      end
      
      def get_catalog_url(a_identifier) 
        # TODO fix catalog to support full, escaped url
        # for POC just use the work and edition
        searchid = a_identifier.to_urn_components[0] + "." + a_identifier.to_urn_components[1]
        return SITE_CATALOG_SEARCH + searchid
      end
      
       # Get the list of creatable identifiers for the supplied urn
      # @param {String} a_urn
      def get_creatable_identifiers(a_urn)
        
      end
      
      # a_inv will either be a SoSOL document identifier or the name of the inventory
      def get_tokenized_passage(a_inv, a_urn,a_tags=[])
		    lang = nil
        documentIdentifier = nil
        tokenizer_url = nil   
        passage_url = nil
        temp_uuid = nil
        
        tokenizer_cfg = Tools::Manager.tool_config('cts_tokenizer',false)
        
        if (!a_inv.nil? && a_inv =~ /^\d+$/)
          documentIdentifier = Identifier.find(a_inv)
          lang = documentIdentifier.lang
          inventory_code = documentIdentifier.related_inventory.name.split('/')[0]
        else
          inventory_code = a_inv
        end
        Rails.logger.info("get_tokenized_passage for #{a_inv} = #{inventory_code}")
        
        if (lang && tokenizer_cfg[lang]) 
          tokenizer_url = tokenizer_cfg[lang][:request_url];
        else
          tokenizer_url = tokenizer_cfg[:default][:request_url];
        end
        
        urn_no_subref = a_urn.sub(/[\#@][^\#@]+$/,'')
        begin
        
          # if we don't have an inventory identifier, and the urn is a url
          # just pass it as-is to the tokenizer
          if (a_inv.nil? && a_urn =~ /^http/)
            Rails.logger.debug("Setting passage url to #{a_urn}")
            passage_url = a_urn
          elsif (getExternalCTSHash().has_key?(inventory_code))
            passage_url = getInventoryUrl(inventory_code) + "&request=GetPassage&urn=#{urn_no_subref}"
          else
             proxy_urn = urn_no_subref.gsub(':','_')
            inventory = documentIdentifier.related_inventory.xml_content
            temp_uuid = documentIdentifier.publication.id.to_s + proxy_urn + '_proxyreq'
            # post inventory and get path for file put 
            uri = URI.parse("#{EXIST_HELPER_REPO}CTS-X.xq?request=CreateCitableText&xuuid=#{temp_uuid}&urn=#{urn_no_subref}")
            response = Net::HTTP.start(uri.host, uri.port) do |http|
              headers = {'Content-Type' => 'text/xml; charset=utf-8'}
              http.send_request('POST',uri.request_uri,inventory,headers)
            end
            if (response.code == '200')
              path = JRubyXML.apply_xsl_transform(
                JRubyXML.stream_from_string(response.body),
                JRubyXML.stream_from_file(File.join(RAILS_ROOT,
                %w{data xslt cts extract_reply_text.xsl})))  
              if (path != '')
                # inventory put succeeded, now put the document itself  
                pathUri = URI.parse("#{EXIST_HELPER_REPO_PUT}#{path}")
                put_response = Net::HTTP.start(pathUri.host, pathUri.port) do |http|
                  headers = {'Content-Type' => 'text/xml; charset=utf-8'}
                  http.send_request('PUT', pathUri.request_uri, documentIdentifier.content,headers)      
                end # end Net::HTTP.start
                if (put_response.code == '201')
                  passage_url = "#{EXIST_HELPER_REPO}CTS.xq?request=GetPassage&inv=#{temp_uuid}&urn=#{urn_no_subref}"
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
            tok_response.response.body
          else 
            raise "Failed request to #{tok_uri} : #{tok_response.code} #{tok_response.msg} #{tok_response.body}" 
          end
        
        ensure
          # cleanup
          if (temp_uuid)
            rurl = URI.parse("#{EXIST_HELPER_REPO}CTS-X.xq?request=DeleteCitableText&urn=#{urn_no_subref}&xuuid=#{temp_uuid}") 
            Net::HTTP.get_response(rurl)
          end
        end
     end
    end #class
  end #module CTSLib
end #module CTS