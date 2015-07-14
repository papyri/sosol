require 'test_helper'
require 'thwait'

class DecreeTest < ActiveSupport::TestCase
  [
    { :tally_method => Decree::TALLY_METHODS[:percent],
      :trigger => 50.0 },
    { :tally_method => Decree::TALLY_METHODS[:count],
      :trigger => 2 }
  ].each do |method|
    context "a #{method[:tally_method]} decree" do
      setup do
        @decree = FactoryGirl.create(:decree,
                          :action => "approve",
                          :trigger => method[:trigger],
                          :tally_method => method[:tally_method],
                          :choices => "yes")
        # add some users to this decree's board
        3.times do |i|
          @decree.board.users << FactoryGirl.create(:user)
        end
      end
    
      teardown do
        @decree.board.users.each {|u| u.destroy}
        @decree.board.destroy
        @decree.destroy
      end
    
      should "have choices" do
        assert @decree.get_choice_array.length > 0
      end
    
      context "with votes on a publication/identifier" do
        setup do
          @publication = FactoryGirl.create(:publication, :owner => @decree.board, :creator => @decree.board.users.first)
          @publication.branch_from_master
          @ddb_identifier = DDBIdentifier.new_from_template(@publication)
        end
      
        teardown do
          @publication.destroy
        end
      
        should "perform action when trigger is met" do
          2.times do |v|
            threads_active_before_vote = Thread.list.select{|t| t.alive?}
            FactoryGirl.create(:vote,
                    :publication => @publication,
                    :identifier_id => @ddb_identifier.id,
                    :user => @decree.board.users[v],
                    :choice => "yes")
            threads_active_after_vote = Thread.list.select{|t| t.alive?}
            new_active_threads = threads_active_after_vote - threads_active_before_vote
            # ThreadsWait.all_waits(*new_active_threads)
          end
          
          assert @decree.perform_action?(@ddb_identifier.votes)
        end
      
        should "not perform action when trigger is not met" do
          threads_active_before_vote = Thread.list.select{|t| t.alive?}
          FactoryGirl.create(:vote,
                  :publication => @publication,
                  :identifier => @ddb_identifier,
                  :user => @decree.board.users[0],
                  :choice => "yes")
          threads_active_after_vote = Thread.list.select{|t| t.alive?}
          new_active_threads = threads_active_after_vote - threads_active_before_vote
          # ThreadsWait.all_waits(*new_active_threads)

          assert !@decree.perform_action?(@ddb_identifier.votes)
        end
      end
    end
  end
end
