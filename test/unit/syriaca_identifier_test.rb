require 'test_helper'

if Sosol::Application.config.site_identifiers.split(',').include?('SyriacaIdentifier')
  class SyriacaIdentifierTest < ActiveSupport::TestCase
    
    context "identifier mapping" do
      setup do
        @path_prefix = SyriacaIdentifier::PATH_PREFIX
      end
      
      should "define the path correctly" do
        item = FactoryGirl.build(:SyriacaIdentifier, :name => "http://syriaca.org/place/2417")
        assert_path_equal %w{place 2417.xml}, item.to_path
      end

      should "define the id_attribute correctly" do
        item = FactoryGirl.build(:SyriacaIdentifier, :name => "http://syriaca.org/place/2417")
        assert_equal "http://syriaca.org/place/2417/tei", item.id_attribute
      end

      should "define the n_attribute correctly" do
        item = FactoryGirl.build(:SyriacaIdentifier, :name => "http://syriaca.org/place/2417")
        assert_equal "place-2417", item.n_attribute
      end
    end

    context "identifier validation" do
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
         
      should "assign a valid identifier" do
        test = SyriacaIdentifier.new_from_template(@publication)
        assert test.name = "http://syriaca.org/place/#{Time.now.year}-1"
      end

      should "validate xml" do
        test = SyriacaIdentifier.new_from_template(@publication)
        assert test.is_valid_xml?
      end

      should "preprocess_for_finalization" do 
        test = SyriacaIdentifier.new_from_template(@publication)
        mock_data  = File.read(File.join(File.dirname(__FILE__), 'data', 'srophe_processed.xml'))
        @agent = stub("mockagent")
        @client = stub("mockclient")
        @client = stub("mockclient")
        @client.stubs(:post_content).returns(mock_data)
        @client.stubs(:get_transformation).returns(nil)
        @client.stubs(:to_s).returns("mock srophe agent")
        AgentHelper.stubs(:get_client).with(@agent).returns(@client)
        AgentHelper.stubs(:agent_of).with(test.name).returns(@agent)
        rc = test.preprocess_for_finalization("dummy")
        assert rc
        assert test.xml_content == mock_data
      end
    end

  end
end
