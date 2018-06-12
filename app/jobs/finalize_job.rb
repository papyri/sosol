class FinalizeJob
  include SuckerPunch::Job

  def perform(publication_id, finalization_comment = '')
    begin
      Rails.logger.debug("FinalizeJob started (publication_id: #{publication_id} finalization_comment: #{finalization_comment})")
      Rails.logger.flush if Rails.logger.respond_to? :flush
      ActiveRecord::Base.connection_pool.clear_reloadable_connections!
      ActiveRecord::Base.connection_pool.with_connection do
        publication = Publication.find(publication_id)
        publication.with_advisory_lock("finalize_#{publication_id}") do
          publication.finalize(finalization_comment)
        end
      end
    ensure
      Rails.logger.debug("FinalizeJob finished (publication_id: #{publication_id} finalization_comment: #{finalization_comment})")
      Rails.logger.flush if Rails.logger.respond_to? :flush
    end
  end
end
