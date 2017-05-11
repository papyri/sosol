class AddToCollectionsJob
  include SuckerPunch::Job
  def perform(identifier_id)
    begin
      Rails.logger.debug("AddToCollectionsJob started (identifier_id: #{identifier_id})")
      Rails.logger.flush if Rails.logger.respond_to? :flush
      ActiveRecord::Base.connection_pool.clear_reloadable_connections!
      ActiveRecord::Base.connection_pool.with_connection do
        identifier = Identifier.find(identifier_id)
        identifier.with_lock do
          user_collection = CollectionsHelper::get_user_collection(identifier.publication.owner, true)
          if user_collection
            CollectionsHelper::put_to_collection(user_collection, identifier)
          end
          # add it to the subject collections
          identifier.get_topics().each do |c|
            topic_collection = CollectionsHelper::get_topic_collection(c, identifier.class.to_s, true)
            if topic_collection
              CollectionsHelper::put_to_collection(topic_collection, identifier)
            end
          end
        end
      end
    ensure
      Rails.logger.debug("AddToCollectionsJob finished (identifier_id: #{identifier_id})")
      Rails.logger.flush if Rails.logger.respond_to? :flush
    end
  end
end

