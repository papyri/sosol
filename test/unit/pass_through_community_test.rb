require 'test_helper'

class PassThroughCommunityTest < ActiveSupport::TestCase
  setup do
    @community = FactoryGirl.create(:master_community, :is_default => true, :name => 'sosolmaster')
    @member = FactoryGirl.create(:user, :name => "member_bob")
  end

  teardown do
    @community.destroy
    @member.destroy
  end

  should "not be able to create a community with itself as the pass_to" do
    assert_raises(ActiveRecord::RecordInvalid) {
      FactoryGirl.create(:pass_through_community, :name => 'pass1', :pass_to => 'pass1')
    }
  end

  should "be able to create a community with the master community as the pass_to" do
    @community2 = FactoryGirl.create(:pass_through_community, :name => 'pass1', :pass_to => 'sosolmaster')
    assert_not_nil @community2
    @community2.destroy
  end
end
