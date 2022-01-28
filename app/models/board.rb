# #Board represents an editorial review board.
class Board < ApplicationRecord
  has_many :decrees, dependent: :destroy
  has_many :emailers, dependent: :destroy

  has_many :votes

  has_many :boards_users
  has_many :users, through: :boards_users
  belongs_to :finalizer_user, class_name: 'User'

  has_many :publications, as: :owner, dependent: :destroy
  has_many :events, as: :owner

  belongs_to :community

  # board rank determines workflow order for publication
  # ranked scopes returns the boards for a given community in order of their rank
  # ranked left as default for sosol ranks
  scope :ranked, -> { where(community_id: nil).order(rank: :asc) }

  scope :ranked_by_community_id, ->(id_in) { where(community_id: id_in).order(rank: :asc) }

  # :identifier_classes is an array of identifier classes this board has
  # commit control over. This isn't done relationally because it's not a
  # relation to instances of identifiers but rather to identifier classes
  # themselves.
  serialize :identifier_classes

  validates :title, uniqueness: { case_sensitive: false, scope: [:community_id] }
  validates :title, presence: true
  validates :title, format: { without: Repository::BASH_SPECIAL_CHARACTERS_REGEX,
                              message: "Board title cannot contain any of the following special characters: #{Repository::BASH_SPECIAL_CHARACTERS_REGEX.source[1..-2]}" }

  has_repository

  # Workaround, repository needs owner name for now.
  def name
    title
  end

  def human_name
    title
  end

  def jgit_actor
    org.eclipse.jgit.lib.PersonIdent.new(title, Sosol::Application.config.site_email_from)
  end

  after_create do |board|
    board.repository.create
  end

  before_destroy do |_board|
    repository.destroy
  end

  # The original idea was to allow programmers to add whatever functionality they wanted to an identifier.
  # This functionality would be contained in a method called result_action_*.
  # When a decree is set up the list of possible result_actions would be parsed from these methods and be presented to the user in a drop down list to choose.
  # Currently (10-10-2011, CSC) I believe this is only used to make the drop down list when creating a decree. The default values are found in the identifier model.
  #
  # *Returns*
  #- string list of possible actions to be taken on an identifier (a.k.a. decree actions)
  def result_actions
    # return array of possible actions that can be implemented
    retval = []
    identifier_classes.each do |ic|
      im = ic.constantize.instance_methods
      match_expression = /(result_action_)/
      im.each do |method_name|
        retval << method_name.to_s.sub(/(result_action_)/, '') if /(result_action_)/.match?(method_name)
      end
    end
    retval
  end

  # *Returns*:
  #- result_actions in a capitalized hash list for the select statement
  def result_actions_hash
    ra = result_actions
    ret_hash = {}

    # create hash
    ra.each do |v|
      ret_hash[v.sub(/_/, ' ').capitalize] = v
    end
    ret_hash
  end

  # *Args*:
  #- +identifier+ identifier or subclass of identifier
  # *Returns*:
  #- +true+ if this board is responsible for the given identifier
  #- +false+ otherwise
  def controls_identifier?(identifier)
    # For APIS boards there is only a single identifier class (APISIdentifier) across
    # all boards.
    if identifier.class.to_s == 'APISIdentifier'
      identifier_classes.include?(identifier.class.to_s) && identifier.name.include?(title.downcase)
    else
      identifier_classes.include?(identifier.class.to_s)
    end
  end

  # Tallies the votes and returns the resulting decree action or returns an empty string if no decree has been triggered.
  #
  # *Args*:
  #- +votes+ the publication's votes
  # *Returns*:
  #- nil if no decree has been triggered
  #- decree action if the votes trigger a decree, if multiple decrees could be triggered by the vote count, only the first in the list will be returned.
  def tally_votes(votes)
    Rails.logger.info("Board#tally_votes on Board: #{inspect}\nWith votes: #{votes.inspect}")
    # NOTE: assumes board controls one identifier type, and user hasn't made
    # rules where multiple decrees can be true at once

    decrees.each do |decree|
      if decree.perform_action?(votes)
        Rails.logger.info("Board#tally_votes success on Board: #{inspect}\nFor decree: #{decree.inspect}\nWith votes: #{votes.inspect}")
        return decree.action
      end
    end

    ''
  end

  # Will generally be called when the status of a publication is changed.
  # Emails will be sent according to emailer settings for the board.
  #
  # *Args*:
  #- +when_to_send+ the new status of the publication.
  #- +publication+ the publication whose status has just changed.
  def send_status_emails(when_to_send, publication)
    # search emailer for status
    return if emailers.nil?

    # find identifiers for email
    email_identifiers = []
    publication.identifiers.each do |identifier|
      email_identifiers << identifier if identifier_classes.include?(identifier.class.to_s)
    end

    emailers.each do |mailer|
      next unless mailer.when_to_send == when_to_send

      # send the email
      addresses = []
      #--addresses

      # board members
      if mailer.send_to_all_board_members
        users.each do |board_user|
          addresses << board_user.email
        end
      end

      # other sosol users
      mailer.users&.each do |user|
        addresses << user.email unless user.email.nil?
      end

      # extra addresses
      if mailer.extra_addresses
        extras = mailer.extra_addresses.split
        extras.each do |extra|
          addresses << extra
        end
      end

      # owner address
      if mailer.send_to_owner && (publication&.creator && publication.creator.email)
        addresses << publication.creator.email
      end
      # the board publication should be the one owned by the board initiating the mail
      # it may or may not be the same as the publication that is the subject of the mail as that
      # depends upon what when_to_send status is.  Traversing all the children of the original publication
      # and selecting the last one which has the current board as its owner should work.
      board_publication = email_identifiers[0].publication.origin.all_children.reverse.find { |p| p.owner == self }
      begin
        EmailerMailer.identifier_email(when_to_send, email_identifiers, board_publication, addresses,
                                       mailer.include_document, mailer.include_comments, mailer.message, mailer.subject).deliver_now
      rescue StandardError => e
        Rails.logger.error("Error sending email: #{e.class}, #{e}")
      end
    end
  end

  # Since friendly_name is an added feature, the existing boards will not have this data, so for backward compatability we may need to make it up.
  # This method could be removed after initial deploy.
  def friendly_name=(fn)
    self[:friendly_name] = if fn && (fn.strip != '')
                             fn
                           else
                             self[:title]
                           end
  end

  # Since board title is used to determine repository names, the title cannot be changed after board creation.
  # This friendly_name allows the users another name that they can change at will.
  # *Returns*:
  #- friendly_name if it has been set. Otherwise returns title.
  def friendly_name
    fn = self[:friendly_name]
    if fn && (fn.strip != '')
      fn
    else
      self[:title]
    end
  end
end
