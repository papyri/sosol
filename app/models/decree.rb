# Decrees represent the possible choices, outcomes and counting methods of a vote.
class Decree < ApplicationRecord
  belongs_to :board

  TALLY_METHODS = { percent: 'percent',
                    count: 'count' }.freeze

  validates_inclusion_of :tally_method,
                         in: TALLY_METHODS.values

  validates_presence_of :tally_method

  # Hash with friendly name for valid tally methods. Mainly for setting selection on forms.
  # Methods are Percentage and Absolute Count.
  def self.tally_methods_hash
    { 'Percentage' => TALLY_METHODS[:percent], 'Absolute Count' => TALLY_METHODS[:count] }
  end

  # *Returns*
  #- an array of the possible choices that represent this decree.
  def get_choice_array
    choices.split
  end

  # *Args*:
  #- +votes+ set of votes to be tallied to determine if decree should be triggered
  # *Returns*:
  #- +true+ if if the given votes tally to trigger the decree
  #- +false+ otherwise
  def perform_action?(votes)
    # pull choices out
    decree_choices = get_choice_array
    # count votes
    decree_vote_count = 0
    votes.each do |vote|
      # see if vote is in choices
      decree_vote_count += 1 if decree_choices.include?(vote.choice)
    end

    # see if we are using percent or min voting counting
    if tally_method == TALLY_METHODS[:percent]
      # percentage
      if decree_vote_count.positive? && board.users.length.to_f.positive?
        percent =  (decree_vote_count.to_f / board.users.length) * 100

        if percent >= trigger
          # check if the action has already been done
          # do the action? or return the action?
          #
          # errMsg += percent.to_s
          return true
        end
      end
    elsif tally_method == Decree::TALLY_METHODS[:count]
      # min absolute vote count
      if decree_vote_count >= trigger
        # check if the action has already been done
        # do the action? or return the action?
        #
        # errMsg += " " + decree_vote_count + " " + vote.choice + " "
        return true
      end
    end

    false
  end
end
