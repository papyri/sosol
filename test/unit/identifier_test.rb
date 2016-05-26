require 'test_helper'

class IdentifierTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "inability to read title doesn't raise error" do
     identifier = FactoryGirl.build(:DDBIdentifier, :name => "papyri.info/ddbdp/bgu;1;1")
     identifier.stubs(:titleize).raises("Unable to Save")
     assert_equal "Invalid Identifier", identifier.title
  end
end
