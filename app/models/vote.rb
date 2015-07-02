#Holds information about a vote.
class Vote < ActiveRecord::Base
  belongs_to :publication
  belongs_to :identifier
  belongs_to :user
  belongs_to :board


  #Ensures vote is tallied after it is committed.
  after_commit :tally, :on => :create

  #Ensures vote is tallied for publication.
  def tally
    if self.identifier # && self.identifier.status == "editing"
      #need to tally votes and see if any action will take place
      #should only be voting while the publication is owned by the correct board
      #related_votes = self.identifier.votes

      #choose vote based on publication votes
      #TODO add votes to be related to publication
      #related_votes = self.publication.votes

      #todo add check to ensure board is correct
      #decree_action = self.publication.tally_votes(related_votes)
      #self.publication.tally_votes(related_votes)

      # We need to call this before spawning a thread to avoid a busy deadlock with SQLite in the test environment
      ActiveRecord::Base.clear_active_connections!

      #let publication decide how to access votes
      Thread.new do
        tries = 3
        begin
          ActiveRecord::Base.connection_pool.clear_reloadable_connections!
          ActiveRecord::Base.connection_pool.with_connection do |conn|
            self.publication.with_lock do
              self.publication.tally_votes()
            end
          end
        rescue ActiveRecord::StatementInvalid => e
          Rails.logger.debug("tally_votes StatementInvalid: #{e.inspect}")
          sleep 1
          ActiveRecord::Base.clear_active_connections!
          retry unless (tries -= 1).zero?
        rescue ActiveRecord::RecordNotFound => e
          Rails.logger.debug("tally_votes RecordNotFound: #{e.inspect}")
          sleep 1
          ActiveRecord::Base.clear_active_connections!
          retry unless (tries -= 1).zero?
        rescue NoMethodError => e
          Rails.logger.debug("tally_votes NoMethodError: #{e.inspect}")
          sleep 1
          ActiveRecord::Base.clear_active_connections!
          retry unless (tries -= 1).zero?
        ensure
          # The new thread gets a new AR connection, so we should
          # always close it and flush logs before we terminate
          ActiveRecord::Base.connection.close
          Rails.logger.flush
        end
      end
    end
    return nil
  end

end
