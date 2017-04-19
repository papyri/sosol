require 'test_helper'

if Sosol::Application.config.site_identifiers.split(',').include?('SyriacaWorkIdentifier')
  class SyriacaWorkIdentifierTest < ActiveSupport::TestCase
    
    context "identifier mapping" do
      setup do
        @path_prefix = SyriacaWorkIdentifier::PATH_PREFIX
      end
      
      should "define the path correctly" do
        item = FactoryGirl.build(:SyriacaWorkIdentifier, :name => "http://syriaca.org/work/1000")
        assert_path_equal %w{work 1000.xml}, item.to_path
      end

      should "define the id_attribute correctly" do
        item = FactoryGirl.build(:SyriacaWorkIdentifier, :name => "http://syriaca.org/work/1000")
        assert_equal "http://syriaca.org/work/1000/tei", item.id_attribute
      end

      should "define the n_attribute correctly" do
        item = FactoryGirl.build(:SyriacaWorkIdentifier, :name => "http://syriaca.org/work/1000")
        assert_equal "work-1000", item.n_attribute
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
        test = SyriacaWorkIdentifier.new_from_template(@publication)
        assert test.name = "http://syriaca.org/work/#{Time.now.year}-1"
      end

      should "validate xml" do
        test = SyriacaWorkIdentifier.new_from_template(@publication)
        assert test.is_valid_xml?
      end
    end

  end
end
