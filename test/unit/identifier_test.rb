require 'test_helper'

class IdentifierTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "inability to read title doesn't raise error" do
     identifier = FactoryGirl.build(:DDBIdentifier, :name => "papyri.info/ddbdp/bgu;1;1")
     identifier.stubs(:titleize).raises("Unable to Save")
     assert_equal "Invalid Identifier", identifier.title
  end

  test "find_like_identifiers handles false response from callback" do
    match_call = lambda do |p| return p.name != @identifier.name end
    matching = Identifier.find_like_identifiers("papyri.info/ddb/bgu;1",@creator,match_call)
    assert_equal [], matching
  end

  test "find_like_identifiers handles true response from callback" do
    match_call = lambda do |p| return p.name == @identifier.name end
    matching = Identifier.find_like_identifiers("papyri.info/ddb/bgu;1",@creator,match_call)
    assert_equal [], matching
  end
end
