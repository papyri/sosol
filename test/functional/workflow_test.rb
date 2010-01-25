require 'test_helper'

class WorkflowTest < ActiveSupport::TestCase
  context "for IDP2" do
    setup do
      @ddb_board = Factory(:board)
    
      3.times do |i|
        @ddb_board.users << Factory(:user)
      end
      
      Factory(:percent_decree,
              :board => @ddb_board,
              :trigger => 50.0,
              :action => "accept",
              :choices => "yes no defer")
      Factory(:percent_decree,
              :board => @ddb_board,
              :trigger => 50.0,
              :action => "reject",
              :choices => "reject")
      Factory(:count_decree,
              :board => @ddb_board,
              :trigger => 1.0,
              :action => "graffiti",
              :choices => "graffiti")
      
      @james = Factory(:user)
      
      @hgv_meta_board = Factory(:hgv_meta_board)
      @hgv_trans_board = Factory(:hgv_trans_board)
      
      @hgv_meta_board.users << @james
      @hgv_trans_board.users << @james
      
      @submitter = Factory(:user)
    end
    
    teardown do
      [ @ddb_board.users, @james, @submitter,
        @ddb_board, @hgv_meta_board, @hgv_trans_board ].each {|entity| entity.destroy}
    end
    
    def generate_board_vote_for_decree(board, decree, identifier)
      Factory(:vote,
              :publication => identifier.publication,
              :identifier => identifier,
              :user => board.users[vote_count],
              :choice => (decree.get_choice_array)[rand(
                decree.get_choice_array.size)])
    end
    
    def generate_board_votes_for_action(board, action, identifier)
      decree = board.decrees.find {|d| d.action == action}
      vote_count = 0
      if decree.tally_method == Decree::TALLY_METHODS(:percent)
        while (((vote_count.to_f / decree.users)*100) < decree.trigger) do
          generate_board_vote_for_decree(board, decree, identifier)
          vote_count += 1
        end
      elsif decree.tally_method == Decree::TALLY_METHODS(:count)
        while (vote_count.to_f < decree.trigger) do
          generate_board_vote_for_decree(board, decree, identifier)
          vote_count += 1
        end
      end
    end

    context "a user submitting a publication with only DDB modifications" do
      setup do
      end
      
      teardown do
      end
      
      should "succeed" do
        assert true
      end
    end
  end
end