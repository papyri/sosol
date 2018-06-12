class TallyVotesJob
  include SuckerPunch::Job

  def perform(publication_id, related_votes)
    begin
      Rails.logger.debug("TallyVotesJob started (publication_id: #{publication_id}, related_votes: #{related_votes.inspect})")
      Rails.logger.flush if Rails.logger.respond_to? :flush
      ActiveRecord::Base.connection_pool.clear_reloadable_connections!
      ActiveRecord::Base.connection_pool.with_connection do
        publication = Publication.find(publication_id)
        publication.with_advisory_lock("tally_votes_#{publication_id}") do
          publication.transaction do
            publication.tally_votes(related_votes)
          end
        end
      end
    ensure
      Rails.logger.debug("TallyVotesJob finished (publication_id: #{publication_id})")
      Rails.logger.flush if Rails.logger.respond_to? :flush
    end
  end
end
