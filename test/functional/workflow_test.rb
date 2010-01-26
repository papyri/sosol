require 'test_helper'

class WorkflowTest < ActiveSupport::TestCase
  context "for IDP2" do
    setup do
      @ddb_board = Factory(:board, :title => 'DDbDP Editorial Board')
    
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
      
      @hgv_meta_board = Factory(:hgv_meta_board, :title => 'HGV metadata')
      @hgv_trans_board = Factory(:hgv_trans_board, :title => 'Translations')
      
      @hgv_meta_board.users << @james
      @hgv_trans_board.users << @james
      
      @submitter = Factory(:user)
    end
    
    teardown do
      [ @ddb_board.users, @james, @submitter,
        @ddb_board, @hgv_meta_board, @hgv_trans_board ].each {|entity| entity.destroy}
    end
    
    def generate_board_vote_for_decree(board, decree, identifier, user)
      Factory(:vote,
              :publication => identifier.publication,
              :identifier => identifier,
              :user => user,
              :choice => (decree.get_choice_array)[rand(
                decree.get_choice_array.size)])
    end
    
    def generate_board_votes_for_action(board, action, identifier)
      decree = board.decrees.find(:all).find {|d| d.action == action}
      vote_count = 0
      if decree.tally_method == Decree::TALLY_METHODS[:percent]
        while (((vote_count.to_f / decree.board.users.length)*100) < decree.trigger) do
          generate_board_vote_for_decree(board, decree, identifier, board.users[vote_count])
          vote_count += 1
        end
      elsif decree.tally_method == Decree::TALLY_METHODS[:count]
        while (vote_count.to_f < decree.trigger) do
          generate_board_vote_for_decree(board, decree, identifier, board.users[vote_count])
          vote_count += 1
        end
      end
    end

    context "a publication" do
      setup do
        @publication = Factory(:publication, :status => "new")
        
        # branch from master so we aren't just creating an empty branch
        @publication.branch_from_master
      end
      
      teardown do
        # @publication.destroy
      end
      
      context "submitted with only DDB modifications" do
        setup do
          @new_ddb = DDBIdentifier.new_from_template(@publication)
          
          @publication.submit
        end
        
        should "be copied to the DDB board" do
          assert_equal @publication, @ddb_board.publications.first.parent
          assert_equal @publication.children, @ddb_board.publications
        end

        should "not be copied to the HGV boards" do
          assert_equal 0, @hgv_meta_board.publications.length
          assert_equal 0, @hgv_trans_board.publications.length
        end
        
        context "voted 'accept'" do
          setup do
            generate_board_votes_for_action(@ddb_board, "accept", @new_ddb)
          end
          
          should "have two 'accept' votes" do
            assert_equal 2, @new_ddb.votes.find(:all).collect {|v| %{yes no defer}.include?(v.choice)}.length
          end
          
          should "be copied to a finalizer" do
            assert_equal 1, @ddb_board.publications.first.children.length
          end
        end
      end
      
    end
  end
end