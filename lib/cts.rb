module CTS
  require 'jruby_xml'
  require 'net/http'
  require "uri"
  
  
  CTS_JAR_PATH = File.join(File.dirname(__FILE__), *%w"java cts3.jar")  
  GROOVY_JAR_PATH = File.join(File.dirname(__FILE__), *%w"java groovy-all-1.6.2.jar")  
  CTS_NAMESPACE = "http://chs.harvard.edu/xmlns/cts3/ti"
  EXIST_HELPER_REPO = "#{EXIST_STANDALONE_URL}/exist/rest/db/xq/CTS.xq?"
  EXIST_HELPER_REPO_PUT = "#{EXIST_STANDALONE_URL}/exist/rest"
  
  module CTSLib
    class << self
      
      # method which returns a CtsUrn object from the java chs cts3 library
      def urnObj(a_urn)
        if(RUBY_PLATFORM == 'java')
          Rails.logger.info("loading #{CTS_JAR_PATH} and #{GROOVY_JAR_PATH}")
          require 'java'
          require CTS_JAR_PATH
          require GROOVY_JAR_PATH
          include_class("edu.harvard.chs.cts3.CtsUrn") { |pkg, name| "J" + name }
          urn = JCtsUrn.new(a_urn)
          Rails.logger.info("created urn #{urn.getTextGroup(true)} #{urn.getWork(true)}")
        else
          require 'rubygems'
          require 'rjb'
          Rjb::load(classpath = ".:#{CTS_JAR_PATH}:#{GROOVY_JAR_PATH}", jvmargs=[])
          cts_urn_class = Rjb::import('edu.harvard.chs.cts3.CtsUrn')
          urn = cts_urn_class.new(a_urn)
        end
        return urn
      end
      
      # method which inserts the publication type (i.e. edition or translation) into the path of a CTS urn
      def pathForUrn(a_urn,a_pubtype) 
        path_parts = a_urn.sub!(/urn:cts:/,'').split(':')
        cite_parts = path_parts[1].split(/\./)
        passage = path_parts[2]
        last_part = cite_parts.length() - 1
        document_path_parts = []
        # we want to end up with NS/authornum.worknum/edition/editionnum.exemplarnum/passage
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
        return EXIST_HELPER_REPO + '&inv=' + a_inventory
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
          if (components[3] == 'textinventory')
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
        uri = URI.parse("#{EXIST_HELPER_REPO}request=GetValidReff&inv=#{a_inventory}&urn=#{a_urn}&level=#{a_level}")
        Rails.logger.info(uri.request_uri)
        response = Net::HTTP.start(uri.host, uri.port) do |http|
          http.send_request('GET',uri.request_uri)
        end
        if (response.code == '200')
           Rails.logger.info(response.body)
           results = JRubyXML.apply_xsl_transform(
                   JRubyXML.stream_from_string(response.body),
                   JRubyXML.stream_from_file(File.join(RAILS_ROOT,
                   %w{data xslt cts validreff_urns.xsl})))  
        else
           nil
        end
      end
            
      def proxyGetPassage(a_inventory,a_document,a_urn,a_uuid)
          passage = ''
          inventory = getInventory(a_inventory)
          Rails.logger.info("Putting inventory for #{a_urn} at #{a_uuid}")
          # post inventory and get path for file put 
          # TODO CTS request should be PutInventory
          # TODO CTS extensions should be at different base URI (e.g. CTS-X)
           uri = URI.parse("#{EXIST_HELPER_REPO}request=PutCitableText&xuuid=#{a_uuid}&urn=#{a_urn}")
           Rails.logger.info("Request=#{uri}")
           response = Net::HTTP.start(uri.host, uri.port) do |http|
                headers = {'Content-Type' => 'text/xml; charset=utf-8'}
                http.send_request('POST',uri.request_uri,inventory,headers)
           end
           if (response.code == '200')
            Rails.logger.info("Response=#{response.body}")
            path = JRubyXML.apply_xsl_transform(
                   JRubyXML.stream_from_string(response.body),
                   JRubyXML.stream_from_file(File.join(RAILS_ROOT,
                   %w{data xslt cts extract_reply_text.xsl})))  
            if (path != '')
              # inventory put succeeded, now put the document itself  
              pathUri = URI.parse("#{EXIST_HELPER_REPO_PUT}#{path}")
              Rails.logger.info("Put Request #{pathUri}") 
              put_response = Net::HTTP.start(pathUri.host, pathUri.port) do |http|
                headers = {'Content-Type' => 'text/xml; charset=utf-8'}
                http.send_request('PUT', pathUri.request_uri, a_document,
headers)      
              end
              if (put_response.code == '201')
              # request passage
                rurl = URI.parse("#{EXIST_HELPER_REPO}request=GetPassagePlus&inv=#{a_uuid}&urn=#{a_urn}")
                Rails.logger.info("Passage Request #{rurl}") 
                psg_response = Net::HTTP.start(rurl.host, rurl.port) do |http|
                  http.send_request('GET', rurl.request_uri)
                end
                if (psg_response.code == '200')
                  passage = JRubyXML.apply_xsl_transform(
                     JRubyXML.stream_from_string(psg_response.body),
                     JRubyXML.stream_from_file(File.join(RAILS_ROOT,
                     %w{data xslt cts extract_getpassage_reply.xsl})))  
                else
                  passage = "<error>Passage request failed #{psg_response.code} #{psg_response.msg}</error>"
                end # psg_response
              else
                passage = "<error>Put text failed #{put_response.code} #{put_response.msg}</error>"
              end # put_response
            else 
                passage = "<error>no path for put</error>"
            end # put_path          
           else # end post inventory
            passage = "<error>Inventory post failed #{response.code} #{response.msg}</error>"
          end
          # cleanup
         #  Net::HTTP.get_response(
         #       "#{EXIST_HELPER_REPO}&request=removeInventory&inv=#{invid}")
         # return passage
      end
      
      def proxyPutPassage(a_psg,a_inventory,a_document,a_urn,a_uuid)
          # load inventory  -> POST inventory -> returns unique identifier for inventory
           uri = URI.parse("#{EXIST_HELPER_REPO}request=PutCitableText&xuuid=#{a_uuid}&urn=#{a_urn}")
           response = Net::HTTP.start(uri.host, uri.port) do |http|
                headers = {'Content-Type' => 'text/xml; charset=utf-8'}
                http.send_request('POST',uri.request_uri,a_inventory,headers)
           end
            # load document -> POST document
           if (response.code == '200')
            Rails.logger.info("Response=#{response.body}")
            path = JRubyXML.apply_xsl_transform(
                   JRubyXML.stream_from_string(response.body),
                   JRubyXML.stream_from_file(File.join(RAILS_ROOT,
                   %w{data xslt cts extract_reply_text.xsl})))  
            if (path != '')
              pathUri = URI.parse("#{EXIST_HELPER_REPO_PUT}#{path}")
              Rails.logger.info("Put Request #{pathUri}") 
              put_response = Net::HTTP.start(pathUri.host, pathUri.port) do |http|
                headers = {'Content-Type' => 'text/xml; charset=utf-8'}
                http.send_request('PUT', pathUri.request_uri, a_document,
headers)      
              end
              if (put_response.code == '201')
              # put passage
                rurl = URI.parse("#{EXIST_HELPER_REPO}request=PutPassage&inv=#{a_uuid}&urn=#{a_urn}")
                Rails.logger.info("Passage Request #{rurl}") 
                psg_response = Net::HTTP.start(rurl.host, rurl.port) do |http|
                  headers = {'Content-Type' => 'text/xml; charset=utf-8'}
                  http.send_request('POST',rurl.request_uri,a_psg,headers)
                end
                if (psg_response.code == '200')
                  # now we return the updated document
                  passage = JRubyXML.apply_xsl_transform(
                     JRubyXML.stream_from_string(psg_response.body),
                     JRubyXML.stream_from_file(File.join(RAILS_ROOT,
                     %w{data xslt cts extract_putpassage_reply.xsl})))  
                else
                  raise "<error>Passage request failed #{psg_response.code} #{psg_response.msg}</error>"
                end # psg_response
              else
                raise "<error>Put text failed #{put_response.code} #{put_response.msg}</error>"
              end # put_response
            else 
                raise "<error>no path for put</error>"
            end # put_path          
           else # end post inventory
            passage = "<error>Inventory post failed #{response.code} #{response.msg}</error>"
          end
          # cleanup
         #  Net::HTTP.get_response(
         #       "#{EXIST_HELPER_REPO}&request=removeInventory&inv=#{invid}")
         # return passage
      end
      
      def get_catalog_url(a_identifier) 
        # TODO fix catalog to support full, escaped url
        # for POC just use the work and edition
        searchid = a_identifier.to_urn_components[0] + "." + a_identifier.to_urn_components[1]
        return SITE_CATALOG_SEARCH + searchid
      end
      
    end #class
  end #module CTSLib
end #module CTS