#Holds information about a vote.
class Vote < ActiveRecord::Base
  belongs_to :publication
  belongs_to :identifier
  belongs_to :user
  belongs_to :board


  #Ensures vote is tallied after it is committed.
  after_commit :tally, :on => :create

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

      related_votes = self.publication.votes(true)
      Rails.logger.info("Vote#tally called for #{self.publication.id} with votes #{related_votes.inspect}")
      TallyVotesJob.new.async.perform(self.publication.id, related_votes)
    end
    return nil
  end

end
