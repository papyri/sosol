require 'test_helper'

if Sosol::Application.config.site_identifiers.split(',').include?('OaCiteIdentifier')
  class OaCiteIdentifierTest < ActiveSupport::TestCase
  
    context "identifier test" do
      setup do
        @creator = FactoryGirl.create(:user, :name => "Creator")
        @publication = FactoryGirl.create(:publication, :owner => @creator, :creator => @creator, :status => "new")

        # branch from master so we aren't just creating an empty branch
        @publication.branch_from_master

        # use a mock Google agent so test doesn't depend upon live google doc
        # test document should produce 9 annotations (from 6 entries in the spreadsheet)
        @client = stub("googless")
        @client.stubs(:get_content).returns(File.read(File.join(File.dirname(__FILE__), 'data', 'google1.xml')))
        @client.stubs(:get_transformation).returns("/data/xslt/cite/gs_to_oa_cite.xsl")
        AgentHelper.stubs(:get_client).returns(@client)
      end
    
      teardown do
        unless @publication.nil?
          @publication.destroy
        end
        unless @creator.nil?
          @creator.destroy
        end
      end

      should "new_from_template creates empty document without init_value" do
        test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
        assert_not_nil test
        assert_equal [], test.get_annotations()
      end

      should "new_from_template works with gss key pub url as init_value" do
        init_value = ["https://docs.google.com/spreadsheet/pub?key=0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc&output=html"]
        test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
        assert_not_nil test
        assert_equal 9, test.get_annotations().size
      end

      should "new_from_template works with gss key link url as init_value" do
        init_value = ["https://docs.google.com/spreadsheet/ccc?key=0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc&usp=sharing"]
        test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
        assert_not_nil test
        assert_equal 9, test.get_annotations().size
      end

      should "new_from_template work with gss pub url as init_value" do
        init_value = ["https://docs.google.com/spreadsheets/d/0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc/pubhtml"]
        test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
        assert_not_nil test
        assert_equal 9, test.get_annotations().size
      end

      should "new_from_template should work with gss link url as init_value" do
        init_value = ["https://docs.google.com/spreadsheets/d/0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc/edit?usp=sharing"]
        test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
        assert_not_nil test
        assert_equal 9, test.get_annotations().size
      end

      should "new_from_template raises error with invalid google url as init_value" do
        init_value = ["https://docs.google.com/spreadsheets/d/0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc"]
        @client.stubs(:get_content).raises("Invalid URL")
        exception = assert_raises(RuntimeError) {
          test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
        }
        assert_match(/^Invalid URL/,exception.message)
      end

      should "find_matching_identifiers should not find collection object" do
        init_value = []
        collection_urn = "urn:cite:perseus:pdlann" 
        one = OaCiteIdentifier.new_from_template(@publication,collection_urn,init_value)
        matching = OaCiteIdentifier.find_matching_identifiers(collection_urn,@creator,init_value)
        assert_equal [], matching
      end

      should "find matching_identifiers should find collection object" do
        init_value = []
        collection_urn = "urn:cite:perseus:pdlann" 
        match_call = lambda do |p| return true 
        end
        one = OaCiteIdentifier.new_from_template(@publication,collection_urn,init_value)
        matching = OaCiteIdentifier.find_matching_identifiers(collection_urn,@creator,match_call)
        assert_equal [one], matching
      end

      should "has_anyannotation? returns true" do
        init_value = ["https://docs.google.com/spreadsheets/d/0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc/pubhtml"]
        test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
        assert test.has_anyannotation?
      end

      should "has_any_annotation? returns false" do
        test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
        assert ! test.has_anyannotation?
      end

      should "get_annotation by uri" do
        init_value = ["https://docs.google.com/spreadsheets/d/0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc/pubhtml"]
        test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
        assert_not_nil test.get_annotation("http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#6-1")
      end

      should "get_annotation by uri returns Nil" do
        init_value = ["https://docs.google.com/spreadsheets/d/0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc/pubhtml"]
        test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
        assert_nil test.get_annotation("http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#7-1")
      end

      should "get_annotations" do
        init_value = ["https://docs.google.com/spreadsheet/ccc?key=0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc&usp=sharing"]
        test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
        assert_equal 9, test.get_annotations().size
      end

      should "matching_targets correctly finds target" do
        init_value = ["https://docs.google.com/spreadsheet/ccc?key=0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc&usp=sharing"]
        test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
        match_str = Regexp.quote("http://www.perseus.tufts.edu/hopper/morph?l=*perse%2Fwn&la=greek&can=*perse%2Fwn0&prior=a)llh/loisi")
        matching = test.matching_targets(match_str)
        should_match = Hash.new
        should_match['id'] = 'http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#1-1'
        should_match['target'] = 'http://www.perseus.tufts.edu/hopper/morph?l=*perse%2Fwn&la=greek&can=*perse%2Fwn0&prior=a)llh/loisi'
        assert_equal should_match, matching[0]
        assert_equal 3, matching.size
      end

      should "matching_targets correctly doesn't find target" do
        init_value = ["https://docs.google.com/spreadsheet/ccc?key=0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc&usp=sharing"]
        test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
        match_str = Regexp.quote("http://example.org")
        matching = test.matching_targets(match_str)
        assert_equal 0, matching.size
      end

      should "create_annotation adds a new annotation"do
        test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
        assert_equal 0, test.get_annotations().size
        test.create_annotation("http://example.org")
        assert_equal 1, test.get_annotations().size
        should_match = Hash.new
        should_match["id"] = "http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#1"
        should_match["target"] = "http://example.org" 
        assert_equal [should_match], test.matching_targets("http://example\.org")
        test.create_annotation("http://example2.org")
        should_match["id"] = "http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#2"
        should_match["target"] = "http://example2.org" 
        assert_equal [should_match], test.matching_targets("http://example2\.org")
      end

      should "delete_annotation deletes an existing annotation"do
        test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
        assert_equal 0, test.get_annotations().size
        test.create_annotation("http://example.org")
        assert_equal 1, test.get_annotations().size
        test.delete_annotation("http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#1","deleteme")
        assert_equal 0, test.get_annotations().size
      end

      should "afer_rename raises error" do
        test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
        assert_raises(RuntimeError) { 
            test.rename("cite/perseus/pdlann.10.1.oac.xml")
        }
        test.reload
        assert_equal "cite/perseus/pdlann.1.1", test.name
      end


      should "api_get with query" do
        test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
        test.create_annotation("http://example.org")
        assert_match /^<Annotation/, test.api_get("uri=http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#1")
      end
      should "api_get invalid query" do
        test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
        assert_raises(RuntimeError){ test.api_get("http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#1") }
      end

      should "api_get no query" do
        test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
        test.create_annotation("http://example.org")
        assert_match /<rdf:RDF/, test.api_get(nil)
      end

      should "api_get not found" do
        test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
        assert_nil test.api_get("uri=http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#1")
      end

      should "api_append" do
        to_append = "<Annotation xmlns=\"http://www.w3.org/ns/oa#\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" rdf:about=\"http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#1\">\n  <hasTarget xmlns=\"http://www.w3.org/ns/oa#\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" rdf:resource=\"http://example.org\"/>\n  <motivatedBy xmlns=\"http://www.w3.org/ns/oa#\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"/>\n  <annotatedBy xmlns=\"http://www.w3.org/ns/oa#\">\n    <Person xmlns=\"http://xmlns.com/foaf/0.1/\" xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\" rdf:about=\"http://data.perseus.org/sosol/users/Creator\"/>\n  </annotatedBy>\n  <annotatedAt xmlns=\"http://www.w3.org/ns/oa#\">2016-03-22T10:13:40-04:00</annotatedAt>\n</Annotation>"
        test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
        test.api_append(nil,to_append,"updatefromapi")
        assert_match /^<Annotation/, test.api_get("uri=http://data.perseus.org/collections/urn:cite:perseus:pdlann.1.1/#1")
      end

      #should "api_append with agent transform" do
          # NOT CURRENTLY USING THIS FUNCTIONALITY - WAS IMPLEMENTED FOR RECOGITO PROTOTYPE WHICH IS NOW REMOVED
      #end

      #should "api_update" do
          # NOT CURRENTLY USING THIS FUNCTIONALITY - WAS IMPLEMENTED FOR RECOGITO PROTOTYPE WHICH IS NOW REMOVED
      #end

      should "can_import? should return true for annotations imported from googless" do
        init_value = ["https://docs.google.com/spreadsheet/pub?key=0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc&output=html"]
        test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
        assert test.can_import?
      end

      should "can_import? should return false for annotations created by native apps" do
        test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",[])
        test.create_annotation("http://example.org")
        assert ! test.can_import?
      end

      #should "api_info" do
        # TODO THIS FUNCTIONAILTY NEEDS TO BE REFACTORED
      #end

    end
   
  end

end
