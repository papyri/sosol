class Decree < ActiveRecord::Base
  belongs_to :board
  
  def get_choice_array
    self.choices.split(',')  
  end
end
