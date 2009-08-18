require 'test_helper'

class BoardTest < ActiveSupport::TestCase
  should "delete its repository upon destruction" do
    board = Factory(:board)
    path = board.repository.path
    assert File.exists?(path)
    board.destroy
    assert !File.exists?(path)
  end
end
