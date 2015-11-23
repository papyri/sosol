class MasterCommunity < Community

  before_destroy :guard_last_master

  # Handles Promotion of a publication to the next 
  # step in the workflow after finalization
  # for a Master community this just
  # sets the status of the original publicaiton
  # to committed as its the final stop
  #*Args*:
  #- +publication+ publication to be promoted
  def promote(publication)
    # this the final stop for this publication
    # so the original publication's status is now
    # committed
    publication.origin.change_status("committed")
  end

  # Community-specific finalization steps
  # Commits the publication to the master repo
  # *Args*:
  #- +publication+ publication to be finalized
  # *Returns*
  # - the commit sha
  def finalize(publication)
    canon_sha = publication.commit_to_canon
  end


  # Guards against destruction
  # can't destroy the last master community
  def guard_last_master
    # we should not destroy the last master community
    # or the default
    unless MasterCommunity.count > 1 
      self.errors[:base] << "We can't destroy the last Master community"
      return false
    end
  end

end
