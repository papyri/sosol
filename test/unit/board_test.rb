require 'test_helper'

class BoardTest < ActiveSupport::TestCase
  context "a created board" do
    setup do
      @board = FactoryGirl.create(:board)
      @decree = FactoryGirl.create(:decree, :board => @board)
      @path = @board.repository.path
    end
    
    subject { @board }
    
    should validate_uniqueness_of(:title).case_insensitive
    
    teardown do
      @board.destroy unless !Board.exists? @board.id
    end
    
    should "have a repository" do
      assert File.exists?(@path)
    end

    should "return rank" do 
        assert_equal [ @board ], Board.ranked_by_community_id( nil )
    end

    
    context "upon destruction" do
      setup do
        @board.destroy
      end
      
      should "delete its repository" do
        assert !File.exists?(@path)
      end
    
      should "destroy associated decrees" do
        assert !Decree.exists?(@decree.id)
      end
    end
  end

  context "a created community board" do
    setup do
      @board = FactoryGirl.create(:community_board)
      @decree = FactoryGirl.create(:decree, :board => @board)
      @path = @board.repository.path
    end
    
    subject { @board }
    
    should validate_uniqueness_of(:title).case_insensitive.scoped_to(:community_id)

    teardown do
      @board.destroy unless !Board.exists? @board.id
    end
    
    should "have a repository" do
      assert File.exists?(@path)
    end

    should "return community rank" do 
        assert_equal [ @board ], Board.ranked_by_community_id( @board.community.id )
    end
    
    context "upon destruction" do
      setup do
        @board.destroy
      end
      
      should "delete its repository" do
        assert !File.exists?(@path)
      end
    
      should "destroy associated decrees" do
        assert !Decree.exists?(@decree.id)
      end
    end
  end
end
