require 'test_helper'

class PublicationTest < ActiveSupport::TestCase
  context "a new publication from templates" do
    setup do
      @user = Factory(:user)
      @publication = Publication.new_from_templates(@user)
    end

    teardown do
      @publication.destroy
      @user.destroy
    end
    
    should "have an equivalent creator and owner" do
      assert_equal @publication.creator, @publication.owner
    end
    
    should "have valid XML for templates" do
      @publication.identifiers.each do |identifier|
        assert identifier.is_valid_xml?
      end
    end
  end
end
