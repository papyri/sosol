class RepackCanonicalJob
  include SuckerPunch::Job

  def perform
    begin
      Rails.logger.debug("RepackCanonicalJob started")
      Rails.logger.flush if Rails.logger.respond_to? :flush
      ActiveRecord::Base.connection_pool.clear_reloadable_connections!
      ActiveRecord::Base.connection_pool.with_connection do
        Publication.with_advisory_lock("repack_canonical") do
          Repository.new.repack()
        end
      end
    ensure
      Rails.logger.debug("RepackCanonicalJob finished")
      Rails.logger.flush if Rails.logger.respond_to? :flush
    end
  end
end
