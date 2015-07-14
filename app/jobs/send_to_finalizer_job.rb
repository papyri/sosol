class SendToFinalizerJob
  include SuckerPunch::Job

  def perform(publication_id, user_id)
    Rails.logger.debug('SendToFinalizerJob started')
    Rails.logger.flush
    ActiveRecord::Base.connection_pool.clear_reloadable_connections!
    ActiveRecord::Base.connection_pool.with_connection do
      publication = Publication.find(publication_id)
      user = User.find(user_id)
      publication.send_to_finalizer(user)
      publication.status = "finalizing"
      publication.save
    end
    Rails.logger.debug('SendToFinalizerJob finished')
    Rails.logger.flush
  end
end
