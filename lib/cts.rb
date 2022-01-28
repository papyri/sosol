module CTS
  require 'jruby_xml'
  require 'net/http'
  require 'uri'

  CTS_JAR_PATH = File.join(File.dirname(__FILE__), *%w[java cts3.jar])
  GROOVY_JAR_PATH = File.join(File.dirname(__FILE__), *%w[java groovy-all-1.6.2.jar])
  CTS_NAMESPACE = 'http://chs.harvard.edu/xmlns/cts3/ti'.freeze
  if defined?(EXIST_STANDALONE_URL)
    EXIST_HELPER_REPO = "#{EXIST_STANDALONE_URL}/exist/rest/db/xq/".freeze
    EXIST_HELPER_REPO_PUT = "#{EXIST_STANDALONE_URL}/exist/rest".freeze
  end

  module CTSLib
    class << self
      # method which returns a CtsUrn object from the java chs cts3 library
      def urnObj(a_urn)
        if RUBY_PLATFORM == 'java'
          require 'java'
          require CTS_JAR_PATH
          require GROOVY_JAR_PATH
          include_class('edu.harvard.chs.cts3.CtsUrn') { |_pkg, name| "J#{name}" }
          urn = JCtsUrn.new(a_urn)
        else
          require 'rubygems'
          require 'rjb'
          Rjb.load(classpath = ".:#{CTS_JAR_PATH}:#{GROOVY_JAR_PATH}", jvmargs = [])
          cts_urn_class = Rjb.import('edu.harvard.chs.cts3.CtsUrn')
          urn = cts_urn_class.new(a_urn)
        end
        urn
      end

      # get a pub type for a urn from the parent inventory
      def versionTypeForUrn(a_inventory, a_urn)
        urn = urnObj(a_urn)
        response = Net::HTTP.get_response(
          URI.parse("#{getInventoryUrl(a_inventory)}&request=GetCapabilities")
        )
        results = JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(response.body),
          JRubyXML.stream_from_file(File.join(Rails.root,
                                              %w[data xslt cts extract_reply.xsl]))
        )
        xml = REXML::Document.new(results)
        xpath = "//ti:textgroup[@projid='#{urn.getTextGroup(true)}']/ti:work[@projid='#{urn.getWork(true)}']/*[@projid='#{urn.getVersion(true)}']"
        node = REXML::XPath.first(xml, xpath, { 'ti' => CTS_NAMESPACE })
        nodeName = nil
        nodeName = node.local_name unless node.nil?
        nodeName
      end

      # method which inserts the publication type (i.e. edition or translation) into the path of a CTS urn
      def pathForUrn(a_urn, a_pubtype)
        path_parts = a_urn.sub!(/urn:cts:/, '').split(':')
        cite_parts = path_parts[1].split(/\./)
        passage = path_parts[2]
        last_part = cite_parts.length - 1
        document_path_parts = []
        # SoSOL CTS identifier path looks like NS/authornum.worknum/pubtype/editionnum.exemplarnum/passage
        # NS
        document_path_parts << path_parts[0]
        # textgroup and work
        document_path_parts << cite_parts[0..1].join('.')
        # edition path insert
        document_path_parts << a_pubtype
        # edition and exemplar
        document_path_parts << cite_parts[2..last_part].join('.')
        # only include the passage if we have one
        document_path_parts << passage unless passage.nil?
        document_path_parts.join('/')
      end

      def workTitleForUrn(doc, a_urn)
        urn = urnObj(a_urn)
        # response = Net::HTTP.get_response(
        #  URI.parse(self.getInventoryUrl(a_inventory) + "&request=GetCapabilities"))
        JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(doc),
          JRubyXML.stream_from_file(File.join(Rails.root,
                                              %w[data xslt cts work_title.xsl])),
          textgroup: urn.getTextGroup(true), work: urn.getWork(true)
        )
      end

      def versionTitleForUrn(a_inventory, a_urn)
        # make sure we have the urn:cts prefix
        a_urn = "urn:cts:#{a_urn}" unless a_urn =~ /^urn:cts:/
        urn = urnObj(a_urn)
        response = Net::HTTP.get_response(
          URI.parse("#{getInventoryUrl(a_inventory)}&request=GetCapabilities")
        )
        JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(response.body),
          JRubyXML.stream_from_file(File.join(Rails.root,
                                              %w[data xslt cts version_title.xsl])),
          textgroup: urn.getTextGroup(true), work: urn.getWork(true), version: urn.getVersion(true)
        )
      end

      def getInventory(a_inventory)
        response = Net::HTTP.get_response(
          URI.parse("#{getInventoryUrl(a_inventory)}&request=GetCapabilities")
        )
        JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(response.body),
          JRubyXML.stream_from_file(File.join(Rails.root,
                                              %w[data xslt cts extract_reply.xsl]))
        )
      end

      def isCTSIdentifier(a_identifier)
        components = a_identifier.split('/')
        getInventoriesHash.key?(components[0])
      end

      def getInventoryUrl(a_inventory)
        # first check the internal repos
        if getExternalCTSHash.key?(a_inventory)
          @external_cts.fetch(a_inventory).fetch('api')
        elsif getInventoriesHash.key?(a_inventory)
          "#{EXIST_HELPER_REPO}CTS.xq?inv=#{a_inventory}"
        else
          Rails.logger.info(@external_cts.inspect)
          raise "#{a_inventory} CTS Repository is not registered."
        end
      end

      def getExternalCTSReposAsJson
        getExternalCTSHash
        repos = {}
        keys = {}
        urispaces = {}
        @external_cts.each_key do |a_key|
          keys[a_key] = @external_cts.fetch(a_key).fetch('urispace')
          urispaces[@external_cts.fetch(a_key).fetch('urispace')] = a_key
        end
        repos['keys'] = keys
        repos['urispaces'] = urispaces
        JSON.generate(repos)
      end

      def getExternalCTSHash
        unless defined? @external_cts
          @external_cts = {}
          if defined?(EXTERNAL_CTS_REPOS)
            EXTERNAL_CTS_REPOS.split(',').each do |entry|
              info = entry.split('|')
              repo_info = {}
              repo_info['api'] = info[1]
              repo_info['urispace'] = info[2]
              @external_cts[info[0]] = repo_info
            end
          end
        end
        @external_cts
      end

      def getInventoriesHash
        unless defined? @inventories_hash
          @inventories_hash = {}
          if defined?(SITE_CTS_INVENTORIES)
            SITE_CTS_INVENTORIES.split(',').each do |entry|
              info = entry.split('|')
              @inventories_hash[info[0]] = info[1]
            end
          end
        end
        @inventories_hash
      end

      def getIdentifierClassName(a_identifier)
        getInventoriesHash
        components = a_identifier.split('/')
        if @inventories_hash.key?(components[0])
          pub_type = ''
          if components[5]
            pub_type = 'Citation'
          elsif components[3] == 'translation'
            pub_type = 'Trans'
          end
          id_type = "#{@inventories_hash.fetch(components[0])}#{pub_type}CTSIdentifier"
          return id_type
        end
        nil
      end

      def getIdentifierKey(a_identifier)
        getInventoriesHash
        components = a_identifier.split('/')
        id_type = nil
        if components.last == 'annotations'
          id_type = 'OACIdentifier'
        elsif components[3] == 'textinventory'
          id_type = 'CTSInventoryIdentifier'
        elsif @inventories_hash.key?(components[0])
          pub_type = ''
          if components[5]
            pub_type = 'Passage'
          elsif components[3] == 'translation'
            pub_type = 'Trans'
          end
          id_type = "#{@inventories_hash.fetch(components[0])}#{pub_type}CTSIdentifier"
        end
        return id_type.constantize::IDENTIFIER_NAMESPACE unless id_type.nil?

        nil
      end

      def getEditionUrns(a_inventory)
        response = Net::HTTP.get_response(
          URI.parse("#{getInventoryUrl(a_inventory)}&request=GetCapabilities")
        )
        JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(response.body),
          JRubyXML.stream_from_file(File.join(Rails.root,
                                              %w[data xslt cts inventory_to_json.xsl]))
        )
      end

      def getTranslationUrns(a_inventory, a_urn)
        urn = urnObj(a_urn)
        response = Net::HTTP.get_response(
          URI.parse("#{getInventoryUrl(a_inventory)}&request=GetCapabilities")
        )
        JRubyXML.apply_xsl_transform(
          JRubyXML.stream_from_string(response.body),
          JRubyXML.stream_from_file(File.join(Rails.root,
                                              %w[data xslt cts inventory_trans_to_json.xsl])),
          e_textgroup: urn.getTextGroup(true), e_work: urn.getWork(true), e_expression: 'translation'
        )
      end

      def proxyGetCapabilities(a_inventory)
        response = Net::HTTP.get_response(
          URI.parse("#{getInventoryUrl(a_inventory)}&request=GetCapabilities")
        )
        response.body
      end

      def proxyGetValidReff(a_inventory, a_urn, a_level)
        uri = URI.parse("#{EXIST_HELPER_REPO}CTS.xq?request=GetValidReff&inv=#{a_inventory}&urn=#{a_urn}&level=#{a_level}")
        response = Net::HTTP.start(uri.host, uri.port) do |http|
          http.send_request('GET', uri.request_uri)
        end
        if response.code == '200'
          results = JRubyXML.apply_xsl_transform(
            JRubyXML.stream_from_string(response.body),
            JRubyXML.stream_from_file(File.join(Rails.root,
                                                %w[data xslt cts validreff_urns.xsl]))
          )
        end
      end

      def getPassageFromRepo(inventory, a_document, a_urn, a_uuid)
        passage = ''
        begin
          # post inventory and get path for file put
          # TODO CTS extensions should be at different base URI (e.g. CTS-X)
          uri = URI.parse("#{EXIST_HELPER_REPO}CTS-X.xq?request=CreateCitableText&xuuid=#{a_uuid}&urn=#{a_urn}")
          response = Net::HTTP.start(uri.host, uri.port) do |http|
            headers = { 'Content-Type' => 'text/xml; charset=utf-8' }
            http.send_request('POST', uri.request_uri, inventory, headers)
          end
          if response.code == '200'
            path = JRubyXML.apply_xsl_transform(
              JRubyXML.stream_from_string(response.body),
              JRubyXML.stream_from_file(File.join(Rails.root,
                                                  %w[data xslt cts extract_reply_text.xsl]))
            )
            if path == ''
              raise 'no path for put'
            else
              # inventory put succeeded, now put the document itself
              pathUri = URI.parse("#{EXIST_HELPER_REPO_PUT}#{path}")
              put_response = Net::HTTP.start(pathUri.host, pathUri.port) do |http|
                headers = { 'Content-Type' => 'text/xml; charset=utf-8' }
                http.send_request('PUT', pathUri.request_uri, a_document,
                                  headers)
              end
              if put_response.code == '201'
                # request passage
                rurl = URI.parse("#{EXIST_HELPER_REPO}CTS.xq?request=GetPassage&inv=#{a_uuid}&urn=#{a_urn}")
                psg_response = Net::HTTP.start(rurl.host, rurl.port) do |http|
                  http.send_request('GET', rurl.request_uri)
                end
                if psg_response.code == '200'
                  passage = JRubyXML.apply_xsl_transform(
                    JRubyXML.stream_from_string(psg_response.body),
                    JRubyXML.stream_from_file(File.join(Rails.root,
                                                        %w[data xslt cts extract_getpassage_reply.xsl]))
                  )
                  passage
                else
                  raise "Passage request failed #{psg_response.code} #{psg_response.msg} #{psg_response.body}"
                end
              else
                raise "Put text failed #{put_response.code} #{put_response.msg} #{put_response.body}"
              end
            end
          else
            raise "Inventory post failed #{response.code} #{response.msg} #{response.body}"
          end
        ensure
          # cleanup
          rurl = URI.parse("#{EXIST_HELPER_REPO}CTS-X.xq?request=DeleteCitableText&urn=#{a_urn}&xuuid=#{a_uuid}")
          Net::HTTP.get_response(rurl)
        end
      end

      def proxyGetPassage(a_inventory, a_urn)
        response = Net::HTTP.get_response(URI.parse(getInventoryUrl(a_inventory) +
          "&request=GetPassage&urn=#{a_urn}"))
        response.body
      end

      def proxyUpdatePassage(a_psg, a_inventory, a_document, a_urn, a_uuid)
        # load inventory  -> POST inventory -> returns unique identifier for inventory
        uri = URI.parse("#{EXIST_HELPER_REPO}CTS-X.xq?request=CreateCitableText&xuuid=#{a_uuid}&urn=#{a_urn}")
        response = Net::HTTP.start(uri.host, uri.port) do |http|
          headers = { 'Content-Type' => 'text/xml; charset=utf-8' }
          http.send_request('POST', uri.request_uri, a_inventory, headers)
        end
        # load document -> POST document
        if response.code == '200'
          path = JRubyXML.apply_xsl_transform(
            JRubyXML.stream_from_string(response.body),
            JRubyXML.stream_from_file(File.join(Rails.root,
                                                %w[data xslt cts extract_reply_text.xsl]))
          )
          if path == ''
            raise 'No path for put'
          else
            pathUri = URI.parse("#{EXIST_HELPER_REPO_PUT}#{path}")
            put_response = Net::HTTP.start(pathUri.host, pathUri.port) do |http|
              headers = { 'Content-Type' => 'text/xml; charset=utf-8' }
              http.send_request('PUT', pathUri.request_uri, a_document, headers)
            end
            if put_response.code == '201'
              # put passage
              rurl = URI.parse("#{EXIST_HELPER_REPO}CTS-X.xq?request=UpdatePassage&inv=#{a_uuid}&urn=#{a_urn}")
              psg_response = Net::HTTP.start(rurl.host, rurl.port) do |http|
                headers = { 'Content-Type' => 'text/xml; charset=utf-8' }
                http.send_request('POST', rurl.request_uri, a_psg, headers)
              end
              if psg_response.code == '200'
                # now we return the updated document
                updated_text = JRubyXML.apply_xsl_transform(
                  JRubyXML.stream_from_string(psg_response.body),
                  JRubyXML.stream_from_file(File.join(Rails.root,
                                                      %w[data xslt cts extract_updatepassage_reply.xsl]))
                )
                # if the parsed response doesn't include the updated text
                # then raise an error so that we don't overwrite the file with blank data
                raise "Update failed: #{psg_response.body}" if updated_text == ''

                updated_text
              else
                raise "Passage request failed #{psg_response.code} #{psg_response.msg}>"
              end
            else
              raise "Put text failed #{put_response.code} #{put_response.msg}"
            end
          end
        else # end post inventory
          raise "Inventory post failed #{response.code} #{response.msg}"
        end
      ensure
        # cleanup
        rurl = URI.parse("#{EXIST_HELPER_REPO}CTS-X.xq?request=DeleteCitableText&urn=#{a_urn}&xuuid=#{a_uuid}")
        Net::HTTP.get_response(rurl)
      end

      def get_catalog_url(a_identifier)
        # TODO: fix catalog to support full, escaped url
        # for POC just use the work and edition
        searchid = "#{a_identifier.to_urn_components[0]}.#{a_identifier.to_urn_components[1]}"
        SITE_CATALOG_SEARCH + searchid
      end
    end
  end
end
