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
    
    should "have status 'new'" do
      assert_equal "new", @publication.status
    end
    
    should "have a head" do
      assert @publication.head
    end
  end
  
  context "a publication copied to another owner" do
    setup do
      @original_owner = Factory(:user)
      @new_owner = Factory(:user)
      @publication = Publication.new_from_templates(@original_owner)
      @publication_copy = @publication.copy_to_owner(@new_owner)
    end
    
    teardown do
      @publication_copy.destroy
      @new_owner.destroy
      
      @publication.destroy
      @original_owner.destroy
    end
    
    should "retain the original creator" do
      assert_equal @publication_copy.creator, @original_owner
    end
    
    should "belong to the new owner" do
      assert_equal @publication_copy.owner, @new_owner
    end
    
    should "have its source as a parent" do
      assert_equal @publication_copy.parent, @publication
    end
    
    should "be a child of its parent" do
      assert @publication.children.include?(@publication_copy)
    end
  end
end
