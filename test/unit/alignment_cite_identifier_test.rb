require 'test_helper'

if Sosol::Application.config.site_identifiers.split(',').include?('AlignmentCiteIdentifier')
  class AlignmentCiteIdentifierTest < ActiveSupport::TestCase
    def silence_warnings(&block)
      warn_level = $VERBOSE
      $VERBOSE = nil
      result = block.call
      $VERBOSE = warn_level
      result
    end
    
    context "identifier test" do
      setup do
        @creator = FactoryGirl.create(:user, :name => "Creator")
        @publication = FactoryGirl.create(:publication, :owner => @creator, :creator => @creator, :status => "new")

        # branch from master so we aren't just creating an empty branch
        @publication.branch_from_master
        @tokenized_lat = File.read(File.join(File.dirname(__FILE__), 'responses', 'tokenized_lat.xml'))
        @oldcts = CTS::CTSLib
        silence_warnings {
          CTS::CTSLib = stub("my tokenizer")
          CTS::CTSLib.stubs(:get_tokenized_passage).returns(@tokenized_lat)
          CTS::CTSLib.stubs(:get_subref).returns('Troiae[1]-venit[1]')
        }
      end
      
      teardown do
        silence_warnings { CTS::CTSLib = @oldcts }
        unless @publication.nil?
          @publication.destroy
        end
        unless @creator.nil?
          @creator.destroy
        end
      end
         
      should "create new from template" do
        test = AlignmentCiteIdentifier.new_from_template(@publication)
        assert_not_nil test
      end
      
      should "create new from supplied" do
        file = File.read(File.join(File.dirname(__FILE__), 'data', 'align1.xml'))
        test = AlignmentCiteIdentifier.new_from_supplied(@publication,"http://example.org",file,"New alignment")
        assert_not_nil test
        # title from comment uris
        assert_equal "urn:cts:greekLit:tlg0020.tlg001.perseus-grc2:1-1 and urn:cts:greekLit:tlg0020.tlg001.perseus-eng2:1-1", test.title
      end

      should "retrieve fragment" do
        file = File.read(File.join(File.dirname(__FILE__), 'data', 'align1.xml'))
        test = AlignmentCiteIdentifier.new_from_supplied(@publication,"http://example.org",file,"New alignment")
        assert_not_nil test
        assert_match /<sentence id="1" document_id="urn:cts:greekLit:tlg0020.tlg001.perseus-grc2:1-1">/, test.fragment("s=1")
      end

      should "raise exceptin on invalid fragment query" do
        file = File.read(File.join(File.dirname(__FILE__), 'data', 'align1.xml'))
        test = AlignmentCiteIdentifier.new_from_supplied(@publication,"http://example.org",file,"New alignment")
        assert_not_nil test
        assert_raises(Exception){
          test.fragment("1")
        }
      end

      should "patch_content" do
        file = File.read(File.join(File.dirname(__FILE__), 'data', 'align1.xml'))
        sentence = File.read(File.join(File.dirname(__FILE__), 'data', 'alignsentence1.xml'))
        test = AlignmentCiteIdentifier.new_from_supplied(@publication,"http://example.org",file,"New alignment")
        assert_not_nil test
        assert_no_match /nrefs="1-1"/, test.fragment("s=1")
        test.patch_content("http://example.org","s=1",sentence,"test")
        test.reload
        assert_match /nrefs="1-1"/, test.fragment("s=1")
      end

     end
     context "identifier ro test" do
       setup do
        @creator = FactoryGirl.create(:user, :name => "Creator")
        @publication = FactoryGirl.create(:publication, :owner => @creator, :creator => @creator, :status => "new")
        @publication.branch_from_master
      end
      
      teardown do
        unless @publication.nil?
          @publication.destroy
        end
        unless @creator.nil?
          @creator.destroy
        end
      end
      should "export ro" do
        file = File.read(File.join(File.dirname(__FILE__), 'data', 'align1.xml'))
        test = AlignmentCiteIdentifier.new_from_supplied(@publication,"http://example.org",file,"New alignment")
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
                             "contents" => "{\n  \"@context\": {\n    \"prov\": \"http://www.w3.org/ns/prov#\"\n  },\n  \"@id\": \"../../data/perseus-align.1.1.xml\",\n  \"@type\": \"prov:Entity\",\n  \"prov:wasDerivedFrom\": [\n    {\n      \"@type\": \"prov:Entity\",\n      \"@id\": \"urn:cts:greekLit:tlg0020.tlg001.perseus-grc2\"\n    },\n    {\n      \"@type\": \"prov:Entity\",\n      \"@id\": \"urn:cts:greekLit:tlg0020.tlg001.perseus-eng2\"\n    }\n  ]\n}"}
         }
         assert_equal(expected, test.as_ro())
      end
    end
  end
end
