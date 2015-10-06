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

  # Promotes a publication to the next step in the workflow
  # after board approval.
  #
  # For an EndUser community this means it gets copied
  # to the designed end user and saved in her space
  # and then the original publication is flagged as
  #  committed
  # 
  # *Args* +publication+ the publication to promote
  #
  def promote(publication)
    #copy to  space
    Rails.logger.debug "----end user to get it"
    Rails.logger.debug self.end_user.name

    community_copy = publication.copy_to_owner(self.end_user, "#{self.name}/#{publication.creator.name}/#{publication.title}") #adding orginal creator to title as reminder for end_user
    community_copy.status = "editing"
    community_copy.identifiers.each do |id|
      id.status = "editing"
      id.save
    end

    #disconnect the parent/origin connections
    community_copy.parent = nil

    #reset the community id to be the default
    # leave as is
    # TODO eventually this will be configurable per community
    # community_copy.community_id = Community.default

    #remove the original creator id (that info is now in the git history )
    community_copy.creator_id = community_copy.owner_id
    community_copy.save!

    # the original publication is done now so we can
    # set the status of the original publication
    # to committed
    publication.origin.change_status("committed")
  end

  def finalize(publication)
    if self.end_user.nil?
      raise "No End User for the community. Unable to finalize"
    end
  end

end
