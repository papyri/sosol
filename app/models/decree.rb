#Decrees represent the possible choices, outcomes and counting methods of a vote.
class Decree < ActiveRecord::Base
  belongs_to :board
  
  TALLY_METHODS = Hash[%w{percent count}.map {|i| [i.to_sym, i]}]
  
  validates_inclusion_of :tally_method,
                         :in => TALLY_METHODS.values
                         
  validates_presence_of :tally_method
  
  def self.tally_methods_hash
  #hash with friendly name for valid tally methods. Mainly for setting selection on forms.
    { "Percentage" => TALLY_METHODS[:percent], "Absolute Count" => TALLY_METHODS[:count]}
  end
  
 # def self.result_actions_hash
  #hash with friendly name for valid decree actions. Mainly for setting selection on forms.
#    {"Approve" => "approve", "Reject" => "reject", "Graffiti" => "graffiti" } 
#  end
  
  #Returns an array of the possible choices that represent this decree.
  def get_choice_array
    self.choices.split(' ')  
  end
end
