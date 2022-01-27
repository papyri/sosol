# frozen_string_literal: true

class FinalizeJob
  include SuckerPunch::Job

  def perform(publication_id, finalization_comment = '')
    Rails.logger.debug("FinalizeJob started (publication_id: #{publication_id} finalization_comment: #{finalization_comment})")
    Rails.logger.flush if Rails.logger.respond_to? :flush
    publication = Publication.find(publication_id)
    publication.finalize(finalization_comment)
  ensure
    Rails.logger.debug("FinalizeJob finished (publication_id: #{publication_id} finalization_comment: #{finalization_comment})")
    Rails.logger.flush if Rails.logger.respond_to? :flush
  end
end
