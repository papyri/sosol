class SubmitJob
  include SuckerPunch::Job

  def perform(publication_id, submission_comment = '')
    Rails.logger.debug do
      "SubmitJob started (publication_id: #{publication_id} submission_comment: #{submission_comment})"
    end
    Rails.logger.flush if Rails.logger.respond_to? :flush
    publication = Publication.find(publication_id)
    publication.submit_with_comment(submission_comment)
  ensure
    Rails.logger.debug do
      "SubmitJob finished (publication_id: #{publication_id} submission_comment: #{submission_comment})"
    end
    Rails.logger.flush if Rails.logger.respond_to? :flush
  end
end
