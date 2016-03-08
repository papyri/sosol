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

      should "work with gss key pub url" do
        init_value = ["https://docs.google.com/spreadsheet/pub?key=0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc&output=html"]
        test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
        assert_not_nil test
      end

      should "work with gss key link url" do
        init_value = ["https://docs.google.com/spreadsheet/ccc?key=0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc&usp=sharing"]
        test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
        assert_not_nil test
      end

      should "work with gss pub url" do
        init_value = ["https://docs.google.com/spreadsheets/d/0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc/pubhtml"]
        test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
        assert_not_nil test
      end

      should "work with gss link url" do
        init_value = ["https://docs.google.com/spreadsheets/d/0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc/edit?usp=sharing"]
        test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
        assert_not_nil test
      end

      should "raise error" do
        init_value = ["https://docs.google.com/spreadsheets/d/0AsEF52NLjohvdGRFcG9KMzFWLUNfQ04zRUtBZjVSUHc"]
        @client.stubs(:get_content).raises("Invalid URL")
        exception = assert_raises(RuntimeError) {
          test = OaCiteIdentifier.new_from_template(@publication,"urn:cite:perseus:pdlann",init_value)
        }
        assert_match(/^Invalid URL/,exception.message)
      end

      should "not find matching collection object" do
        init_value = []
        collection_urn = "urn:cite:perseus:pdlann" 
        one = OaCiteIdentifier.new_from_template(@publication,collection_urn,init_value)
        matching = OaCiteIdentifier.find_matching_identifiers(collection_urn,@creator,init_value)
        assert_equal [], matching
      end

      should "find matching collection object" do
        init_value = []
        collection_urn = "urn:cite:perseus:pdlann" 
        match_call = lambda do |p| return true 
        end
        one = OaCiteIdentifier.new_from_template(@publication,collection_urn,init_value)
        matching = OaCiteIdentifier.find_matching_identifiers(collection_urn,@creator,match_call)
        assert_equal [one], matching
      end


    end
   
     # TODO new version from existing version - same annotator 
     # TODO new version from existing version - new annotator (adds annotator)
     # TODO rename updates uri
  end

end
