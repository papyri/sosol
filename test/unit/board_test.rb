require 'test_helper'

class BoardTest < ActiveSupport::TestCase
  context 'a created board' do
    setup do
      @board = FactoryBot.create(:board)
      @decree = FactoryBot.create(:decree, board: @board)
      @path = @board.repository.path
    end

    subject { @board }

    # should validate_uniqueness_of(:title).case_insensitive

    teardown do
      @board.destroy if Board.exists? @board.id
    end

    should 'have a repository' do
      assert File.exist?(@path)
    end

    context 'upon destruction' do
      setup do
        @board.destroy
      end

      should 'delete its repository' do
        assert !File.exist?(@path)
      end

      should 'destroy associated decrees' do
        assert !Decree.exists?(@decree.id)
      end
    end
  end
end
