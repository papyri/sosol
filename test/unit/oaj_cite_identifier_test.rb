require 'test_helper'

class OajCiteIdentifierTest < ActiveSupport::TestCase
  
  context "identifier test" do
    setup do
      @creator = Factory(:user, :name => "Creator")
      @publication = Factory(:publication, :owner => @creator, :creator => @creator, :status => "new")

      # branch from master so we aren't just creating an empty branch
      @publication.branch_from_master
    
    end
    
    teardown do
      unless @publication.nil?
        @publication.destroy
      end
      unless @creator.nil?
        #@creator.destroy
      end
    end

    should "work with valid" do
      init_value = File.read(File.join(File.dirname(__FILE__), 'data', 'valid.json'))
      urn = "urn:cite:perseus:pdljann.123456"
      test = OajCiteIdentifier.new_from_supplied(@publication,urn,init_value)
      assert_not_nil test
      assert_equal "urn:cite:perseus:pdljann.123456.1", test.urn_attribute
    end

    should "raise error" do
      urn = "urn:cite:perseus:pdljann.123456"
      init_value = "<xml>junk</xml>"
      exception = assert_raises(JSON::ParserError) {
        test = OajCiteIdentifier.new_from_supplied(@publication,urn,init_value)
       }
    end

  end
   
end
