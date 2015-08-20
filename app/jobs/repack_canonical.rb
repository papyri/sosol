class RepackCanonical
  include SuckerPunch::Job

  def perform
    Repository.new.repack()
    Rails.logger.flush if Rails.logger.respond_to? :flush
  end
end
