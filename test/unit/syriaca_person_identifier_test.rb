require 'test_helper'

if Sosol::Application.config.site_identifiers.split(',').include?('SyriacaPersonIdentifier')
  class SyriacaPersonIdentifierTest < ActiveSupport::TestCase
    
    context "identifier mapping" do
      setup do
        @path_prefix = SyriacaPersonIdentifier::PATH_PREFIX
      end
      
      should "define the path correctly" do
        item = FactoryGirl.build(:SyriacaPersonIdentifier, :name => "http://syriaca.org/place/2417")
        assert_path_equal %w{place 2417.xml}, item.to_path
      end

      should "define the id_attribute correctly" do
        item = FactoryGirl.build(:SyriacaPersonIdentifier, :name => "http://syriaca.org/place/2417")
        assert_equal "http://syriaca.org/place/2417/tei", item.id_attribute
      end

      should "define the n_attribute correctly" do
        item = FactoryGirl.build(:SyriacaPersonIdentifier, :name => "http://syriaca.org/place/2417")
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
        test = SyriacaPersonIdentifier.new_from_template(@publication)
        assert test.name = "http://syriaca.org/place/#{Time.now.year}-1"
      end

      should "validate xml" do
        test = SyriacaPersonIdentifier.new_from_template(@publication)
        assert test.is_valid_xml?
      end
    end

  end
end
