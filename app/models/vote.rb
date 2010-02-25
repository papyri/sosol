class Vote < ActiveRecord::Base
  belongs_to :publication
  belongs_to :identifier
  belongs_to :user
  belongs_to :board
  

  def after_save
    self.tally
  end
  
  def tally
    if self.identifier # && self.identifier.status == "editing"
      #need to tally votes and see if any action will take place
      #should only be voting while the publication is owned by the correct board
      related_votes = self.identifier.votes
      #todo add check to ensure board is correct
      decree_action = self.publication.tally_votes(related_votes)
    end    
    return nil
  end

end
