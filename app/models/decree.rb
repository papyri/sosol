#Decrees represent the possible choices, outcomes and counting methods of a vote.
class Decree < ActiveRecord::Base
  belongs_to :board
  #Returns an array of the possible choices that represent this decree.
  def get_choice_array
    self.choices.split(' ')  
  end
end
