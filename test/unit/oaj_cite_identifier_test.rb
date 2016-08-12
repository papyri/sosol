require 'test_helper'

if Sosol::Application.config.site_identifiers.split(',').include?('OajCiteIdentifier')
  class OajCiteIdentifierTest < ActiveSupport::TestCase
    
    context "identifier test" do
      setup do
        @creator = FactoryGirl.create(:user, :name => "Creator")
        @publication = FactoryGirl.create(:publication, :owner => @creator, :creator => @creator, :status => "new")

        # branch from master so we aren't just creating an empty branch
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

      should "work with valid" do
        init_value = File.read(File.join(File.dirname(__FILE__), 'data', 'valid.json'))
        test = OajCiteIdentifier.new_from_supplied(@publication,"http://example.org",init_value,"imported")
        assert_not_nil test
      end

      should "raise error" do
        init_value = "<xml>junk</xml>"
        exception = assert_raises(JSON::ParserError) {
          test = OajCiteIdentifier.new_from_supplied(@publication,"http://example.org",init_value,"imported")
        }
      end

    end
     
  end
end
