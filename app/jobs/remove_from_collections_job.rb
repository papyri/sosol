class RemoveFromCollectionsJob
  include SuckerPunch::Job
  def perform(collections,member_id)
    begin
      Rails.logger.debug("RemoveFromCollectionsJob started (identifier_id: #{member_id})")
      Rails.logger.flush if Rails.logger.respond_to? :flush
      collections.each do |c| 
        unless c.nil?
          CollectionsHelper::delete_from_collection(c,member_id)
        end
      end
    ensure
      Rails.logger.debug("RemoveFromCollectionsJob finished (identifier_id: #{member_id})")
      Rails.logger.flush if Rails.logger.respond_to? :flush
    end
  end
end

