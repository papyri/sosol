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
end
