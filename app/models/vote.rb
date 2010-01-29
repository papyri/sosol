class Vote < ActiveRecord::Base
  belongs_to :publication
  belongs_to :identifier
  belongs_to :user
  belongs_to :board
  

  def after_save
    self.tally
  end
  
  def tally
  #  if self.identifier && self.identifier.status == "editing"
      #need to tally votes and see if any action will take place
      #should only be voting while the publication is owned by the correct board
      related_votes = self.identifier.votes
      #todo add check to ensure board is correct
      decree_action = self.publication.tally_votes(related_votes)
      #arrrggg status vs action....could assume that voting will only take place if status is submitted, but that will limit our workflow options?
      #NOTE here are the types of actions for the voting results
      #approve, reject, graffiti

=begin
      # create an event if anything happened
      if !decree_action.nil? && decree_action != ''
        e = Event.new
        e.owner = self.publication.owner
        e.target = self.publication
        e.category = "marked as \"#{decree_action}\""
        e.save!
      end


      if decree_action == "approve"
        #@publication.get_category_obj().approve
        self.identifier.status = "approved"
        self.identifier.save
        #@publication.status = "approved"
        #@publication.save
        # @publication.send_status_emails(decree_action)
      elsif decree_action == "reject"
        #todo implement throughback
        self.identifier.status = "reject"     
        self.identifier.save
        # @publication.send_status_emails(decree_action)
      elsif decree_action == "graffiti"               
        # @publication.send_status_emails(decree_action)
        #do destroy after email since the email may need info in the artice
        #@publication.get_category_obj().graffiti
        self.identifier.destroy #need to destroy related?
        #this part of the publication was crap, do we assume the rest is as well?
        #for now we will just continue the submition process
        self.publication.submit_to_next_board

        #redirect_to url_for(dashboard)
        return
      else
        #unknown action or no action
      end
    #end
=end    
    return nil
  end

end
