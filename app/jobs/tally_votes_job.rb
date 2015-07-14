class TallyVotesJob
  include SuckerPunch::Job

  def perform(publication_id)
    Rails.logger.debug('TallyVotesJob started')
    Rails.logger.flush
    ActiveRecord::Base.connection_pool.clear_reloadable_connections!
    ActiveRecord::Base.connection_pool.with_connection do
      publication = Publication.find(publication_id)
      publication.with_lock do
        publication.tally_votes()
      end
    end
    Rails.logger.debug('TallyVotesJob finished')
    Rails.logger.flush
  end
end
