class SendToAutoFinalizerJob
  include SuckerPunch::Job

  def perform(publication_id, user_id = nil, next_board = nil)
    begin
      Rails.logger.debug("SendToAutoFinalizerJob started (publication_id: #{publication_id} user_id: #{user_id})")
      Rails.logger.flush if Rails.logger.respond_to? :flush
      ActiveRecord::Base.connection_pool.clear_reloadable_connections!
      ActiveRecord::Base.connection_pool.with_connection do
        publication = Publication.find(publication_id)
        publication.with_lock do
          user = User.find(user_id) unless user_id.nil?
          publication.send_to_finalizer_and_finalize(user,next_board)
        end
      end
    rescue Exception => e
      addresses = []
      # this is an exception scenario so send the email to the site admins
      User.where(:admin => true).each do | admin |
        addresses << admin.email
      end
      body_content = "Failure on autofinalize job for publication #{publication_id}. #{e.message}"
      EmailerMailer::general_email(addresses, "Failed to autofinalize", body_content, article_content=nil).deliver
    ensure
      Rails.logger.debug("SendToAutoFinalizerJob finished (publication_id: #{publication_id} user_id: #{user_id})")
      Rails.logger.flush if Rails.logger.respond_to? :flush
    end
  end
end
