require 'test_helper'

class MasterCommunityTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  setup do
    @community = FactoryGirl.create(:master_community, :is_default => true, :name => 'sosolmaster')
    @member = FactoryGirl.create(:user, :name => "member_bob")
    @member2 = FactoryGirl.create(:user, :name => "member_jane")
  end

  teardown do 
    @community.destroy
  end

  should "be able to add a member" do
    @community.members << @member
    assert_equal [@community], @member.community_memberships
  end

  should "be able to call add_member" do
    @community.add_member( @member2.id )
    assert_equal [@community], @member2.community_memberships
  end

  should "not be able to destroy the last master community" do
    assert ! @community.destroy  
  end

  should "be able to destroy a non-last community" do
    @community2 = FactoryGirl.create(:master_community, :name => 'sosolmaster2')
    assert @community2.destroy  
  end

  should "not be able to destroy a non-last default community" do
    @community2 = FactoryGirl.create(:master_community, :name => 'sosolmaster2')
    Community.change_default(@community2)
    @community.reload
    assert !@community.is_default?
    
    assert @community.destroy  
    assert !@community2.destroy  
  end
end
