class RecoverBranchJob
  include SuckerPunch::Job

  def perform(publication_id)
    Rails.logger.debug { "RecoverBranchJob started (publication_id: #{publication_id})" }
    Rails.logger.flush if Rails.logger.respond_to? :flush
    publication = Publication.find(publication_id)
    publication.recover_branch
  ensure
    Rails.logger.debug { "RecoverBranchJob finished (publication_id: #{publication_id})" }
    Rails.logger.flush if Rails.logger.respond_to? :flush
  end
end
