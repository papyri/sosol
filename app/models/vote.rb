class Vote < ActiveRecord::Base
  belongs_to :publication
  belongs_to :identifier
  belongs_to :user
  belongs_to :board
  
 
=begin
  def after_save
    #need to tally votes and see if any action will take place
    self.publication.tally_votes(@vote.identifier.votes)
  end
=end
end
