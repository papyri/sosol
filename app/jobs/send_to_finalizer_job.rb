class SendToFinalizerJob
  include SuckerPunch::Job

  def perform(publication_id, user_id = nil)
    begin
      Rails.logger.debug("SendToFinalizerJob started (publication_id: #{publication_id} user_id: #{user_id})")
      Rails.logger.flush if Rails.logger.respond_to? :flush
      ActiveRecord::Base.connection_pool.clear_reloadable_connections!
      ActiveRecord::Base.connection_pool.with_connection do
        publication = Publication.find(publication_id)
        publication.with_lock do
          publication.with_advisory_lock("become_finalizer_#{publication_id}") do
            user = User.find(user_id) unless user_id.nil?
            publication.send_to_finalizer(user)
          end
        end
      end
    ensure
      Rails.logger.debug("SendToFinalizerJob finished (publication_id: #{publication_id} user_id: #{user_id})")
      Rails.logger.flush if Rails.logger.respond_to? :flush
    end
  end
end
