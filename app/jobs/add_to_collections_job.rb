class AddToCollectionsJob
  include SuckerPunch::Job
  def perform(identifier_id)
    begin
      Rails.logger.debug("AddToCollectionsJob started (identifier_id: #{identifier_id})")
      Rails.logger.flush if Rails.logger.respond_to? :flush
      ActiveRecord::Base.connection_pool.clear_reloadable_connections!
      ActiveRecord::Base.connection_pool.with_connection do
        identifier = Identifier.find(identifier_id)
        collections = identifier.get_collections()
        # add it to publication and user collections
        collections.each do |c|
          begin
            CollectionsHelper::put_to_collection(c, identifier, true)
          rescue Exception => e
            Rails.logger.error(e)
            Rails.logger.warn("Unable to post to collection for #{c.id.to_s} #{identifier.to_s}")
          end
        end
      end
    ensure
      Rails.logger.debug("AddToCollectionsJob finished (identifier_id: #{identifier_id})")
      Rails.logger.flush if Rails.logger.respond_to? :flush
    end
  end
end

