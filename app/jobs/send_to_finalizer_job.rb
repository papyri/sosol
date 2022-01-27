# frozen_string_literal: true

class SendToFinalizerJob
  include SuckerPunch::Job

  def perform(publication_id, user_id = nil)
    Rails.logger.debug("SendToFinalizerJob started (publication_id: #{publication_id} user_id: #{user_id})")
    Rails.logger.flush if Rails.logger.respond_to? :flush
    publication = Publication.find(publication_id)
    if Rails.env != 'test'
      publication.with_advisory_lock("tally_votes_#{publication_id}") do
        # this just creates a hard barrier so that the tally votes rename doesn't race with
        # publication.send_to_finalizer
      end
    end
    publication.with_advisory_lock("become_finalizer_#{publication_id}") do
      publication.reload
      user = User.find(user_id) unless user_id.nil?
      publication.send_to_finalizer(user)
    end
  ensure
    Rails.logger.debug("SendToFinalizerJob finished (publication_id: #{publication_id} user_id: #{user_id})")
    Rails.logger.flush if Rails.logger.respond_to? :flush
  end
end
