require 'test_helper'
class TopicTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "get id" do
     topic = Topic.new("test")
     assert_equal "test", topic.id
  end
end
