require 'test_helper'

class CommunityTest < ActiveSupport::TestCase

  setup do
    @community = FactoryGirl.create(:community, :is_default => true, :name => 'sosolmaster')
  end

  teardown do 
    @community.destroy
  end

  should "have a community" do
    assert_not_nil @community
  end

  should "be set to default community" do
    assert @community.is_default
  end

  should "have a default community" do
    assert_not_nil Community.default.id
    assert_equal @community.id, Community.default.id 
  end
end
