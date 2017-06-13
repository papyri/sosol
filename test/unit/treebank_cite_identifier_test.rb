require 'test_helper'

if Sosol::Application.config.site_identifiers.split(',').include?('TreebankCiteIdentifier')
  class TreebankCiteIdentifierTest < ActiveSupport::TestCase
    
    context "identifier test" do
      setup do
        @creator = FactoryGirl.create(:user, :name => "Creator")
        @publication = FactoryGirl.create(:publication, :owner => @creator, :creator => @creator, :status => "new")
        # branch from master so we aren't just creating an empty branch

        # branch from master so we aren't just creating an empty branch
        @publication.branch_from_master
        CTS::CTSLib.stubs(:urn_abbr).returns("Latin Work")
      end
      
      teardown do
        unless @publication.nil?
          @publication.destroy
        end
        unless @creator.nil?
          @creator.destroy
        end
      end


      should "get identifier_from_content" do
        file = File.read(File.join(File.dirname(__FILE__), 'data', 'bobstb1.xml'))
        (id,content) = TreebankCiteIdentifier.identifier_from_content("http://example.org",file)
        assert_match /^cite\/perseus\/lattb/, id
        # we should have the date now
        assert_match /<date>.*<\/date>/, content
      end

      should "create new from template" do
        test = TreebankCiteIdentifier.new_from_template(@publication)
        assert_not_nil test
      end

      should "create new from supplied" do
        file = File.read(File.join(File.dirname(__FILE__), 'data', 'ctstb.xml'))
        test = TreebankCiteIdentifier.new_from_supplied(@publication,"http://example.org",file,"New treebank")
        assert_not_nil test
        assert_equal "Treebank of Latin Work", test.title
      end

      should "retrieve fragment" do
        file = File.read(File.join(File.dirname(__FILE__), 'data', 'ctstb.xml'))
        test = TreebankCiteIdentifier.new_from_supplied(@publication,"http://example.org",file,"New treebank")
        assert_not_nil test
        assert_match /<sentence id="1" document_id="urn:cts:latinLit:phi1221.phi007.perseus-lat1"/, test.fragment("s=1")

      end

      should "raise exception on invalid fragment query" do
        file = File.read(File.join(File.dirname(__FILE__), 'data', 'ctstb.xml'))
        test = TreebankCiteIdentifier.new_from_supplied(@publication,"http://example.org",file,"New treebank")
        assert_not_nil test
        assert_raises(Exception){
          test.fragment("1")
        }
      end

      should "patch_content" do
        file = File.read(File.join(File.dirname(__FILE__), 'data', 'ctstb.xml'))
        updated = File.read(File.join(File.dirname(__FILE__), 'data', 'ctstb2.xml'))
        test = TreebankCiteIdentifier.new_from_supplied(@publication,"http://example.org",file,"New treebank")
        assert_not_nil test
        assert_no_match /form="extra"/, test.fragment("s=1")
        test.patch_content("http://example.org",nil,updated,"test")
        test.reload
        # new form added
        assert_match /form="extra"/, test.fragment("s=1")
        # and the word count should be renumbered
        assert_match /word id="19" form="."/, test.fragment("s=1")
      end

      should "add annotator" do
        file = File.read(File.join(File.dirname(__FILE__), 'data', 'ctstb.xml'))
        test = TreebankCiteIdentifier.new_from_supplied(@publication,"http://example.org",file,"New treebank")
        assert_not_nil test
        creator_uri = "#{Sosol::Application.config.site_user_namespace}#{URI.escape(@publication.creator.name)}"
        assert_equal 1, test.content.scan(/<uri>#{creator_uri}/).size
      end

      should "get_editor_agent" do
        file = File.read(File.join(File.dirname(__FILE__), 'data', 'ctstb.xml'))
        test = TreebankCiteIdentifier.new_from_supplied(@publication,"http://example.org",file,"New treebank")
        assert_not_nil test
        editor_agent = test.get_editor_agent
        assert_not_nil editor_agent
        assert_equal 'arethusa', editor_agent
      end

      should "get_reviewer_agent" do
        file = File.read(File.join(File.dirname(__FILE__), 'data', 'ctstbgold.xml'))
        test = TreebankCiteIdentifier.new_from_supplied(@publication,"http://example.org",file,"New treebank")
        assert_not_nil test
        reviewer_agent = test.get_reviewer_agent
        assert_not_nil reviewer_agent
        assert_equal 'arethusa', reviewer_agent
      end

      should "match_on_url" do
        file = File.read(File.join(File.dirname(__FILE__), 'data', 'bobstb1.xml'))
        test = TreebankCiteIdentifier.new_from_supplied(@publication,"http://testapp",file,"apicreate")
        assert test.is_match?(["http://bobsfiles.com/1.xml"])
      end

      should "match_on_url_urn" do
        file = File.read(File.join(File.dirname(__FILE__), 'data', 'ctsurl.xml'))
        test = TreebankCiteIdentifier.new_from_supplied(@publication,"http://testapp",file,"apicreate")
        assert test.is_match?(["http://perseids.org/annotsrc/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1"])
      end

      should "match_on_url_urn_with_urn" do
        file = File.read(File.join(File.dirname(__FILE__), 'data', 'ctsurl.xml'))
        test = TreebankCiteIdentifier.new_from_supplied(@publication,"http://testapp",file,"apicreate")
        assert test.is_match?(["urn:cts:greekLit:tlg0012.tlg001.perseus-grc1"])
        assert test.is_match?(["urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1"])
        assert test.is_match?(["urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1-1.2"])
        assert test.is_match?(["http://perseids.org/annotsrc/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1-1.2"])
        assert test.is_match?(["http://perseids.org/annotsrc/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1"])
      end

      should "match_on_url_urn_with_urn_no_range" do
        file = File.read(File.join(File.dirname(__FILE__), 'data', 'ctsurlnorange.xml'))
        test = TreebankCiteIdentifier.new_from_supplied(@publication,"http://testapp",file,"apicreate")
        assert test.is_match?(["urn:cts:greekLit:tlg0012.tlg001.perseus-grc1"])
        assert test.is_match?(["urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.1"])
        assert ! test.is_match?(["urn:cts:greekLit:tlg0012.tlg001.perseus-grc1:1.2"])
      end

      # this test is failing - the cts lib is doing something weird with the xml
      # bit -- reenable test when we upgrade to CTS 5
      #should "not_match_on_url_urn_with_extension" do
      #  file = File.read(File.join(File.dirname(__FILE__), 'data', 'ctsurl.xml'))
      #  test = TreebankCiteIdentifier.new_from_supplied(@publication,"http://testapp",file,"apicreate")
      #  assert ! test.is_match?(["http://perseids.org/annotsrc/urn:cts:greekLit:tlg0012.tlg001.perseus-grc1.xml"])
      #end
       should "return resource object data" do
         file = File.read(File.join(File.dirname(__FILE__), 'data', 'ctstb.xml'))
         test = TreebankCiteIdentifier.new_from_supplied(@publication,"http://testapp",file,"apicreate")
         expected = {
           "annotations" => [],
           "aggregates"=> [
              {  'conformsTo' => test.schema,
                 "mediatype"=>"application/xml",
                 "uri"=>"../data/#{test.download_file_name}",
                 "history" => "provenance/#{test.download_file_name.sub(/.xml$/, '.prov.jsonld')}",
                 "createdBy"=>{"name"=> @creator.full_name, "uri"=> @creator.uri}},
           ],
           "provenance" => { "file" => "provenance/#{test.download_file_name.sub(/.xml$/,'.prov.jsonld')}", 
                             "contents" => "{\n  \"@context\": {\n    \"prov\": \"http://www.w3.org/ns/prov#\"\n  },\n  \"@id\": \"../../data/perseus-lattb.1.1.xml\",\n  \"@type\": \"prov:Entity\",\n  \"prov:wasDerivedFrom\": [\n    {\n      \"@type\": \"prov:Entity\",\n      \"@id\": \"urn:cts:latinLit:phi1221.phi007.perseus-lat1\"\n    },\n    {\n      \"@type\": \"prov:Entity\",\n      \"@id\": \"urn:cts:latinLit:phi1221.phi007.perseus-lat1:appendix\"\n    },\n    {\n      \"@type\": \"prov:Entity\",\n      \"@id\": \"urn:cts:latinLit:phi1221.phi007.perseus-lat1:0-5\"\n    }\n  ]\n}"
                            }
         }
         assert_equal(expected, test.as_ro())
       end

        should "return default remote_path" do
          file = File.read(File.join(File.dirname(__FILE__), 'data', 'ctstb.xml'))
          test = TreebankCiteIdentifier.new_from_supplied(@publication,"http://testapp",file,"apicreate")
          assert_equal 'CITE_TREEBANK_XML/perseus/lattb/1/lattb.1.1.tb.xml', test.to_remote_path
        end

        should "return override remote_path" do
          file = File.read(File.join(File.dirname(__FILE__), 'data', 'remotetb.xml'))
          test = TreebankCiteIdentifier.new_from_supplied(@publication,"http://testapp",file,"apicreate")
          assert_equal 'data/caesar.tb.xml', test.to_remote_path
        end

     end

  end
end
