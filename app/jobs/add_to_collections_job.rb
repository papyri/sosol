class AddToCollectionsJob
  include SuckerPunch::Job
  def perform(identifier_id)
    begin
      Rails.logger.debug("AddToCollectionsJob started (identifier_id: #{identifier_id})")
      Rails.logger.flush if Rails.logger.respond_to? :flush
      ActiveRecord::Base.connection_pool.clear_reloadable_connections!
      ActiveRecord::Base.connection_pool.with_connection do
        identifier = Identifier.find(identifier_id)
        # add it to publication and user collections
        [identifier.publication, identifier.publication.owner].each do |c|
          collection = CollectionsHelper::get_collection(c, true)
          if collection
            CollectionsHelper::put_to_collection(collection, identifier)
          else
             Rails.logger.warn("Unable to retrieve collection for " + c.to_s)
          end
        end

        # add it to the subject collections
        identifier.get_topics().each do |c|
          topic_collection = CollectionsHelper::get_collection(Topic.new(c), true, identifier.class.to_s)
          if topic_collection
            CollectionsHelper::put_to_collection(topic_collection, identifier)
          else
             Rails.logger.warn("Unable to retrieve topic collection for " + identifier.to_s)
          end
        end
      end
    ensure
      Rails.logger.debug("AddToCollectionsJob finished (identifier_id: #{identifier_id})")
      Rails.logger.flush if Rails.logger.respond_to? :flush
    end
  end
end

