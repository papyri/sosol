#Holds information about user assignments for voting and finalization
class Assignment < ActiveRecord::Base
  belongs_to :publication
  belongs_to :user
  belongs_to :board
  has_one :vote

end
