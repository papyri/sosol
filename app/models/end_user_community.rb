# an End User community is one which funnels publications
# to a designated end-user. Publications finalized by
# this type of community are placed in the editing workspace
# of the community end-user after finalization.
class EndUserCommunity < Community


  #The end_user is a sosol user to whom the communities' finalized publications are copied.
  def end_user
    if self.end_user_id.nil?
      return nil  
    end
      return User.find_by_id(self.end_user_id)
  end

  #Checks to see whether or not to allow members to submit to the community
  # Overrides the base class method to require an end_user
  #
  #*Returns*
  #- true if the community is setup properly to receive submissions
  #- false if community should not be submitted to
  def is_submittable?
    #if there is nowhere for the final publication to go, don't let them submit
    #if there are no boards to review the publication, don't let them submit
    return !self.end_user.nil? && (self.boards && self.boards.length > 0)
  end

end
