class FinalizeJob
  include SuckerPunch::Job

  def perform(publication_id, finalization_comment = '')
    Rails.logger.debug do
      "FinalizeJob started (publication_id: #{publication_id} finalization_comment: #{finalization_comment})"
    end
    Rails.logger.flush if Rails.logger.respond_to? :flush
    publication = Publication.find(publication_id)
    publication.finalize(finalization_comment)
  ensure
    Rails.logger.debug do
      "FinalizeJob finished (publication_id: #{publication_id} finalization_comment: #{finalization_comment})"
    end
    Rails.logger.flush if Rails.logger.respond_to? :flush
  end
end
