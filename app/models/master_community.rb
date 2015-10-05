class MasterCommunity < Community

  # Community-specific finalization steps
  # Commits the publication to the master repo
  # *Args*:
  #- +publication+ publication to be finalized
  # *Returns*
  # - the commit sha
  def finalize(publication)
    canon_sha = publication.commit_to_canon
  end


end
