#Holds information about a vote.
class Vote < ActiveRecord::Base
  belongs_to :publication
  belongs_to :identifier
  belongs_to :user
  belongs_to :board
  

  #Ensures vote is tallied after it is saved.
  def after_save
    self.tally
  end
  
  #Ensures vote is tallied for publication.
  def tally
    if self.identifier # && self.identifier.status == "editing"
      #need to tally votes and see if any action will take place
      #should only be voting while the publication is owned by the correct board
      #related_votes = self.identifier.votes
      
      #choose vote based on publication votes
      #TODO add votes to be related to publication 
      #related_votes = self.publication.votes
      
      #todo add check to ensure board is correct
      #decree_action = self.publication.tally_votes(related_votes)
      #self.publication.tally_votes(related_votes)
      
      #let publication decide how to access votes
      self.publication.tally_votes()
    end    
    return nil
  end

end
