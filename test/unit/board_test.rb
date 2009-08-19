require 'test_helper'

class BoardTest < ActiveSupport::TestCase
  context "an existing board" do
    setup do
      @board = Factory(:board)
      @path = @board.repository.path
    end
    
    subject { @board }
    
    should_validate_uniqueness_of :title
    
    teardown do
      @board.destroy unless !Board.exists? @board.id
    end
    
    should "have a repository" do
      assert File.exists?(@path)
    end
  
    should "delete its repository upon destruction" do
      @board.destroy
      assert !File.exists?(@path)
    end
  end
end
