class RepackCanonicalJob
  include SuckerPunch::Job

  def perform
    Rails.logger.debug('RepackCanonicalJob started')
    Rails.logger.flush if Rails.logger.respond_to? :flush
    Publication.with_advisory_lock('repack_canonical') do
      Repository.new.repack
    end
  ensure
    Rails.logger.debug('RepackCanonicalJob finished')
    Rails.logger.flush if Rails.logger.respond_to? :flush
  end
end
