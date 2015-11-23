require 'test_helper'

class CommunityTest < ActiveSupport::TestCase

  setup do
    @community = FactoryGirl.create(:community, :is_default => true, :name => 'sosolmaster')
    @member = FactoryGirl.create(:user, :name => "member_bob")
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

  should "not be able to create another default" do
    assert ! FactoryGirl.build(:community, :is_default => true, :name => 'sosolmaster2').valid?
  end

  should "not be able to destroy the default" do
    assert !@community.destroy
  end

  should "be able to change default community" do
    @community2 = FactoryGirl.create(:community, :name => 'sosolmaster2')
    Community.change_default(@community2)
    @community.reload
    assert @community2.is_default?
    assert ! @community.is_default?
  end

end
