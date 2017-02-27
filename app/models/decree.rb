#Decrees represent the possible choices, outcomes and counting methods of a vote.
class Decree < ActiveRecord::Base
  belongs_to :board
  has_many :rules

  TALLY_METHODS = {:percent => "percent",
                   :count => "count"}
  
  validates_inclusion_of :tally_method,
                         :in => TALLY_METHODS.values
                         
  validates_presence_of :tally_method

  validates_inclusion_of :action,
                         :in => %w{approve reject graffiti}

  validates_presence_of :action
  
  #Hash with friendly name for valid tally methods. Mainly for setting selection on forms.
  #Methods are Percentage and Absolute Count.
  def self.tally_methods_hash
    { "Percentage" => TALLY_METHODS[:percent], "Absolute Count" => TALLY_METHODS[:count]}
  end
  
  #*Returns*
  #- an array of the possible choices that represent this decree. 
  def get_choice_array
    self.choices.split(' ')  
  end
  
  # Check to see if a vote is for the action of a given decree
  # *Args*
  # - +vote+ a vote to check to see if it is for the action of this decree
  # *Returns*: true or false
  def is_vote_for_action?(vote)
    decree_choices = self.get_choice_array
    return decree_choices.include?(vote.choice)
  end

  #*Args*:
  #- +votes+ set of votes to be tallied to determine if decree should be triggered
  #- +trigger_override+ optional trigger value can be supplied override what is set on the decree
  #*Returns*:
  #- +true+ if if the given votes tally to trigger the decree
  #- +false+ otherwise
  def perform_action?(votes,trigger_override=nil)
    use_trigger = trigger_override.nil? ? self.trigger : trigger_override
    #pull choices out
    decree_choices = self.get_choice_array
    #count votes
    decree_vote_count = 0
    votes.each do |vote|
      #see if vote is in choices
      if decree_choices.include?(vote.choice)
        decree_vote_count = decree_vote_count + 1
      end
    end

    #see if we are using percent or min voting counting
    if tally_method == TALLY_METHODS[:percent]
      #percentage
      if decree_vote_count > 0 && self.board.users.length.to_f > 0
        percent =  (decree_vote_count.to_f / self.board.users.length.to_f) * 100

        if percent >= use_trigger
          #check if the action has already been done
          #do the action? or return the action?
          #   
          #errMsg += percent.to_s
          return true
        end
      end
    elsif tally_method == Decree::TALLY_METHODS[:count]
      #min absolute vote count
      if decree_vote_count >= use_trigger
        #check if the action has already been done
        #do the action? or return the action?
        #
        #errMsg += " " + decree_vote_count + " " + vote.choice + " " 
        return true
      end
    end
    
    return false
  end
end
