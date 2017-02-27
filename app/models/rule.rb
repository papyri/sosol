# Rules can be associated with Decrees to enable Decree actions to take place in certain conditions.
# Conditions are currently limited to a combination of a number of days passed since the last vote 
# and a floor threshold on number or percentage votes (whichever is configured for the decree).  
#
# Example:
#   A Decree calls for 5 votes to initiate an action 
#   A rule can be associated which has an expiration date of 30 days and a floor of 3 votes
#   This rule can be applied to initiate the Decree action on the 31st day after the last vote 
#   if at least 3 votes for the Decree have already been made.
#
# Rules are not automatically applied, they must be initiated through a controller action.
# The model class only determines if the rule *can* be applied.
class Rule < ActiveRecord::Base
  attr_accessible :expire_days, :floor, :decree_id
  belongs_to :decree

  # Tests whether the rule can be applied given the supplied votes
  # *Args*
  # - +votes+ set of votes to be tallied to determine if the rule thresholds are met
  # *Returns*
  # - true if the thresholds are met and the rule can be applied
  # - false if the thresholds are not met
  def apply_rule?(votes)
    last_date = nil
    votes.each do |v|
      if last_date.nil? || v.updated_at > last_date
        last_date = v.updated_at
      end
    end
    now = DateTime.now()
    return ! last_date.nil? && (now >= last_date + self.expire_days.days) && self.decree.perform_action?(votes,self.floor)
  end

end
