require 'test_helper'

class DecreeTest < ActiveSupport::TestCase
  [{:tally_method => Decree::TALLY_METHODS[:percent],
    :trigger => 0.5},
   {:tally_method => Decree::TALLY_METHODS[:count],
    :trigger => 2}].each do |method|
    context "a #{method[:tally_method]} decree" do
      setup do
        @decree = Factory(:decree,
                          :action => "approve",
                          :trigger => method[:trigger],
                          :tally_method => method[:tally_method],
                          :choices => "yes")
        # add some users to this decree's board
        3.times do |i|
          @decree.board.users << Factory(:user)
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
          @publication = Factory(:publication, :owner => @decree.board.users.first)
          @ddb_identifier = Factory(:DDBIdentifier, :publication => @publication)
        end
      
        teardown do
          @publication.destroy
        end
      
        should "perform action when trigger is met" do
          2.times do |v|
            Factory(:vote,
                    :publication => @publication,
                    :identifier => @ddb_identifier,
                    :user => @decree.board.users[v],
                    :choice => "yes")
          end

          assert @decree.perform_action?(@ddb_identifier.votes)
        end
      
        should "not perform action when trigger is not met" do
          Factory(:vote,
                  :publication => @publication,
                  :identifier => @ddb_identifier,
                  :user => @decree.board.users[0],
                  :choice => "yes")
        
          assert !@decree.perform_action?(@ddb_identifier.votes)
        end
      end
    end
  end
end
