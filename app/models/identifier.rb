# - Super-class of all identifiers
class Identifier < ApplicationRecord
  IDENTIFIER_SUBCLASSES = Sosol::Application.config.site_identifiers.split(',')

  FRIENDLY_NAME = 'Base Identifier'.freeze

  IDENTIFIER_STATUS = %w[new editing submitted approved finalizing committed archived].freeze

  validates_presence_of :name, :type

  belongs_to :publication

  # assume we want to delete the comments along with the identifier
  has_many :comments, dependent: :destroy

  has_many :votes, dependent: :destroy

  validates_each :type do |record, attr, value|
    unless Sosol::Application.config.site_identifiers.split(',').include?(value)
      record.errors.add attr,
                        "Identifier must be one of #{Sosol::Application.config.site_identifiers}"
    end
  end

  attr_accessor :unsaved_xml_content

  require 'jruby_xml'

  delegate :url_helpers, to: 'Rails.application.routes'

  # - *Returns* :
  #   - all identifier classes enabled for the site
  def self.site_identifier_classes
    site_classes = []
    site_identifiers = Sosol::Application.config.site_identifiers.split(',')
    Identifier::IDENTIFIER_SUBCLASSES.each do |identifier_class|
      site_classes << identifier_class if site_identifiers.include?(identifier_class.to_s)
    end
    site_classes
  end

  # - *Returns* :
  #   - the originally created publication of this identifier (publciation that does not have a parent id)
  def origin
    publication.origin.identifiers.detect { |i| i.name == name && i.type == type }
  end

  # - *Returns* :
  #   - the parent publication of this identifier
  def parent
    publication.parent.identifiers.detect { |i| i.name == name && i.type == type }
  end

  # - *Returns* :
  #   - all the children of the publication that contains this identifier
  def children
    child_identifiers = []
    publication.children.each do |child_pub|
      child_identifiers << child_pub.identifiers.detect { |i| i.name == name && i.type == type }
    end
    child_identifiers
  end

  # - *Returns* :
  #   - this idenfier's origin publication and the origin children, but not self
  def relatives
    if origin.nil?
      []
    else
      [origin] + origin.children - [self]
    end
  end

  # - *Returns* :
  #   - the repository for the owner of this identifier
  def repository
    publication.nil? ? Repository.new : publication.owner.repository
  end

  # - *Returns* :
  #   - the repository branch for this identifier
  def branch
    publication.nil? ? 'master' : publication.branch
  end

  # - *Returns* :
  #   - the cotent of the file containing this identifier from the repository
  def content
    repository.get_file_from_branch(
      to_path, branch
    )
  end

  # Validation of indentifier XML file against tei-epidoc.rng file
  # - *Args*  :
  #   - +content+ -> XML to validate if passed in, pulled from repository if not passed in
  # - *Returns* :
  #   - true/false
  def is_valid_xml?(content = nil)
    content = xml_content if content.nil?
    self.class::XML_VALIDATOR.instance.validate(
      JRubyXML.input_source_from_string(content)
    )
  end

  # Put stuff in here you want to do do all identifiers before a commit is done
  # - currently no logic is in here - just returns whatever was passed in
  # - intended to be overridden by Identifier subclasses, if necessary
  def before_commit(content)
    content
  end

  # Commits identifier XML to the repository
  # - *Args*  :
  #   - +content+ -> the XML you want committed to the repository
  #   - +options+ -> hash of options to pass to repository (ex. - :comment, :actor)
  # - *Returns* :
  #   - a String of the SHA1 of the commit
  def set_content(content, options = {})
    options.reverse_merge! comment: ''
    commit_sha = repository.commit_content(to_path,
                                           branch,
                                           content,
                                           options[:comment],
                                           options[:actor])
    self.modified = true
    save! unless id.nil?

    publication&.update_attribute(:updated_at, Time.now)

    commit_sha
  end

  # Retrieve the commits made to a file in the repository
  # - *Returns* :
  #   - array of commits
  def get_commits(num_commits = 1)
    commit_ids = repository.get_log_for_file_from_branch(
      to_path, branch, num_commits
    )
  end

  def commit_id_to_hash(commit_id)
    commit = {}
    commit[:id] = commit_id
    commit_data = Repository.run_command("#{repository.git_command_prefix} log -n 1 --pretty=format:\"%s%n%an%n%cn%n%at%n%ct\" #{commit_id}").split("\n")
    commit[:message], commit[:author_name], commit[:committer_name], commit[:authored_date], commit[:committed_date] = commit_data
    commit[:message] = commit[:message].empty? ? '(no commit message)' : commit[:message]
    commit[:authored_date] = Time.at(commit[:authored_date].to_i)
    commit[:committed_date] = Time.at(commit[:committed_date].to_i)
    commit
  end

  # Parse out most recent sha from log
  # - *Returns* :
  #   - id of latest commit as a string
  def get_recent_commit_sha
    commits = get_commits
    commits.blank? ? '' : commits.first
  end

  # Create consistent title for identifiers
  # - *Returns* :
  #   - title of identifier
  def titleize
    title = nil
    if instance_of?(HGVMetaIdentifier)
      title = NumbersRDF::NumbersHelper.identifier_to_title(name)
    elsif instance_of?(HGVTransIdentifier)
      title = NumbersRDF::NumbersHelper.identifier_to_title(
        name.sub(/trans/, '')
      )
    elsif instance_of?(APISIdentifier)
      title = name.split('/').last
    elsif instance_of?(DCLPMetaIdentifier) || instance_of?(DCLPTextIdentifier)
      title = name.split('/').last unless name =~ /#{self.class::TEMPORARY_COLLECTION}/
    end

    if title.nil?
      if instance_of?(DDBIdentifier) || (name =~ /#{self.class::TEMPORARY_COLLECTION}/)
        collection_name, volume_number, document_number =
          to_components.last.split(';')
        collection_name =
          self.class.collection_names_hash[collection_name]

        # strip leading zeros
        document_number.sub!(/^0*/, '')

        title = if collection_name.nil?
                  name.split('/').last
                else
                  [collection_name, volume_number, document_number].reject(&:blank?).join(' ')
                end

        title += ' (reprinted)' if respond_to?('is_reprinted?') && is_reprinted?
      else # HGV with no name
        title =  [self.class::FRIENDLY_NAME, name.split('/').last.tr(';', ' ')].join(' ')
      end
    end
    title
  end

  # Splits out identifier file path from the identifier model name field into the separate components
  # - *Returns* :
  #   - components
  def to_components
    trimmed_name = NumbersRDF::NumbersHelper.identifier_to_local_identifier(name)
    # trimmed_name.sub!(/^\/#{self.class::IDENTIFIER_NAMESPACE}\//,'')
    components = NumbersRDF::NumbersHelper.identifier_to_components(trimmed_name)
    components.map!(&:to_s)

    components
  end

  # Creates an array of all the collection names for the associated identifier class (HGV, DDB, APIS)
  # - *Returns* :
  #   - array of collection names
  def self.collection_names
    unless defined? @collection_names
      parts = NumbersRDF::NumbersHelper.identifier_to_parts([NumbersRDF::NAMESPACE_IDENTIFIER,
                                                             self::IDENTIFIER_NAMESPACE].join('/'))
      raise NumbersRDF::Timeout if parts.nil?

      @collection_names = parts.collect { |p| NumbersRDF::NumbersHelper.identifier_to_components(p).last }
    end
    @collection_names
  end

  # Create default XML file and identifier model entry for associated identifier class
  # - *Args*  :
  #   - +publication+ -> the publication the new translation is a part of
  # - *Returns* :
  #   - new identifier
  def self.new_from_template(publication)
    new_identifier = new(name: next_temporary_identifier)

    Identifier.transaction do
      publication.lock!
      if publication.identifiers.select { |i| i.instance_of?(self) }.length.positive?
        return nil
      else
        new_identifier.publication = publication
        new_identifier.save!
      end
    end

    initial_content = new_identifier.file_template
    new_identifier.set_content(initial_content, comment: 'Created from SoSOL template',
                                                actor: publication.owner.instance_of?(User) ? publication.owner.jgit_actor : publication.creator.jgit_actor)

    new_identifier
  end

  # Processes ERB file from retrieved default XML file template for the associated identifier class
  # in data/templates/
  # - *Returns* :
  #   - evaluated file template as string
  def file_template
    template_path = File.join(Rails.root, %w[data templates],
                              "#{self.class.to_s.underscore}.xml.erb")

    template = ERB.new(File.new(template_path).read, nil, '-')

    id = id_attribute
    n = n_attribute
    title = xml_title_text

    template.result(binding)
  end

  # Determines the next 'SoSOL' temporary name for the associated identifier
  # - starts at '1' each year
  # - *Returns* :
  #   - temporary identifier name
  def self.next_temporary_identifier
    year = Time.now.year
    latest = Identifier.where('name like ?',
                              "papyri.info/#{self::IDENTIFIER_NAMESPACE}/#{self::TEMPORARY_COLLECTION};#{year};%").order('name DESC').limit(1).first
    document_number = if latest.nil?
                        # no constructed id's for this year/class
                        1
                      else
                        latest.to_components.last.split(';').last.to_i + 1
                      end

    format("papyri.info/#{self::IDENTIFIER_NAMESPACE}/#{self::TEMPORARY_COLLECTION};%04d;%04d",
           year, document_number)
  end

  # Determines the user who own's this identifer based on the publication it is a part of
  # - *Returns* :
  #   - identifier owner
  def owner
    publication&.owner
  end

  # Determines who can edit the identifier
  # - owner can edit any of their stuff if it is not submitted
  # - only let the board edit if they own it
  # - let the finalizer edit the identifier the board owns
  #
  # - *Returns* :
  #   - true/false
  def mutable?
    # only let the board edit if they own it
    if publication.owner_type == 'Board' && publication.status == 'editing'
      return true if publication.owner.identifier_classes.include?(self.class.to_s)

    # let the finalizer edit the id the board owns
    elsif publication.status == 'finalizing' && publication.find_first_board && publication.find_first_board.identifier_classes.include?(self.class.to_s)
      return true

    # they can edit any of their stuff if it is not submitted
    elsif publication.owner_type == 'User' && %w[editing new].include?(publication.status)
      return true
    end

    false
  end

  # - *Returns* :
  #   - the content of the associated identifier's XML file
  def xml_content
    unsaved_xml_content.presence || content
  end

  # Commits identifier XML to the repository vis set_content
  # - *Args*  :
  #   - +content+ -> the XML you want committed to the repository
  #   - +options+ -> hash of options to pass to repository (ex. - :comment, :actor)
  # - *Returns* :
  #   - a String of the SHA1 of the commit
  def set_xml_content(content, options)
    default_actor = org.eclipse.jgit.lib.PersonIdent.new(Sosol::Application.config.site_full_name,
                                                         Sosol::Application.config.site_email_from)
    default_actor = owner.jgit_actor unless owner.nil?

    options.reverse_merge!(
      validate: true,
      actor: default_actor
    )

    content = before_commit(content)
    commit_sha = ''
    commit_sha = set_content(content, options) if options[:validate] && is_valid_xml?(content)

    self.unsaved_xml_content = nil

    commit_sha
  end

  # Used to rename an identifier from the 'SoSOL' temporary name to the correct 'collection' name
  # - also renames and 'relatives' of the identifier
  # - *Args*  :
  #   - +new_name+ -> name the finalizer has provided
  #   - +options+ -> hash of options to pass to repository (ex. - :comment, :actor)
  # - *Returns* :
  #   - a String of the SHA1 of the commit
  def rename(new_name, options = {})
    original = dup
    options[:original] = original
    options[:new_name] = new_name

    original_name = name
    original_path = to_path
    original_relatives = relatives

    transaction do
      self.name = new_name
      self.title = titleize
      save!

      new_path = to_path
      commit_message = "Rename #{self.class::FRIENDLY_NAME} from '#{original_name}' (#{original_path}) to '#{new_name}' (#{new_path})"

      repository.rename_file(original_path,
                             new_path,
                             branch,
                             commit_message,
                             owner.jgit_actor)

      # rename origin and children
      original_relatives.each do |relative|
        relative.name = new_name
        relative.title = title
        relative.save!

        # rename the file on the relative
        relative.repository.rename_file(original_path,
                                        new_path,
                                        relative.branch,
                                        commit_message,
                                        owner.jgit_actor)
      end
      after_rename(options)
    end
  end

  # Place anything actions you need performed on all identifiers after a 'rename' has occurred
  # - nothin in here at this time
  def after_rename(options = {}); end

  # Determines if identifier is in a temporary collection and so needs renaming before finalization.
  # - *Returns* :
  #   - true/false
  def needs_rename?
    if defined?(self.class::TEMPORARY_COLLECTION) && (to_components[2] =~ %r{^#{self.class::TEMPORARY_COLLECTION}[.;/]})
      return true
    end

    false
  end

  # Added to speed up dashboard since titleize can be slow
  # - gets the title from the identifier model if it exists, otherwise creates it using titleize and saves
  #   it in the model
  # - *Returns* :
  #   - title from identifer model
  def title
    if read_attribute(:title).blank?
      write_attribute(:title, titleize)
      save
    end
    read_attribute(:title)
  end

  # Add a 'change' tag into the tei:revisionDesc of the identifer's XML file via XSLT
  # - does not do a commit - just modifies XML and returns it
  # - *Args*  :
  #   - +text+ -> the comment the user/system has provided
  #   - +user_info+ ->  used in the 'who' attribute of the 'change' tag if give, otherwise uses the publications creator
  #   - +input_content+ -> the XML you want this added to, otherwise pulls it from the repository for this identifier
  # - *Returns* :
  #   - string of the XML containing the added 'change' tag
  def add_change_desc(text = '', user_info = publication.creator, input_content = nil, timestamp = Time.now.xmlschema)
    doc = JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(input_content.nil? ? xml_content : input_content),
      JRubyXML.stream_from_file(File.join(Rails.root,
                                          %w[data xslt common add_change.xsl])),
      who: url_helpers.url_for(host: Sosol::Application.config.site_user_namespace, controller: 'user',
                               action: 'show', user_name: user_info.name, only_path: false),
      comment: text,
      when: timestamp
    )

    doc.to_s
  end

  # Add a 'change' tags to the tei:revisionDesc of the identifer's XML file via XSLT during the finalization process
  # - add a 'change' tag for each vote on the identifier
  # - add a 'change' tag for finalization message
  # - build a commit message that contains the voting comments/users and finalzation comment/user
  # - commits the additions to the repository
  # - *Args*  :
  #   - +comment_text+ -> the comment the user has provided
  #   - +user+ ->  the 'user' that supplied the comment - used in the 'who' attribute of the 'change' tag
  def update_revision_desc(comment_text, user)
    commit_message = "Update revisionDesc\n\n"
    change_desc_content = xml_content

    # assume context is from finalizing publication, so parent is board's copy
    parent_classes = parent.owner.identifier_classes

    Comment.where(publication_id: publication.origin.id).each do |c|
      next unless parent_classes.include?(c.identifier.class.to_s)

      change_desc_content = add_change_desc("#{c.reason.capitalize} - " + c.comment, c.user, change_desc_content,
                                            c.created_at.localtime.xmlschema)
      commit_message += " - #{c.reason.capitalize} - #{c.comment} (#{c.user.human_name})\n"
    end

    change_desc_content = add_change_desc("Finalized - #{comment_text}", user, change_desc_content)
    commit_message += " - Finalized - #{comment_text} (#{user.human_name})"

    set_xml_content(change_desc_content, comment: commit_message)
  end

  # See documentation of result_actions method of board model
  def result_action_approve
    self.status = 'approved'
    publication.send_to_finalizer
  end

  # See documentation of result_actions method of board model
  def result_action_reject
    self.status = 'rejected'
  end

  # See documentation of result_actions method of board model
  def result_action_graffiti
    # delete
  end

  # Determines if identifier in board members dashboard needs reviewing by that member
  # - *Returns*
  #   - +true+ if the identifier needs reviewing
  #   - +false+ if does not need reviewing
  def needs_reviewing?(user_id)
    modified? && publication.status == 'voting' && publication.owner_type == 'Board' && publication.owner.controls_identifier?(self) && !publication.user_has_voted?(user_id) # !self.user_has_voted?(user_id)
  end

  # Determines whether a specified user has voted on this identifier or not
  # - *Args*  :
  #   - +user_id+ -> the id of the user checking to see if voted or not
  # - *Returns* :
  #   - true/false
  def user_has_voted?(user_id)
    votes&.each do |vote|
      if vote.user_id == user_id
        return true # user has a vote on record for this identifier
      end
    end
    # no vote found
    false
  end

  ## identifier classes which need further automatic processing after approval but before
  ## finalization should override this method -- the default does nothing
  def preprocess_for_finalization
    # default does nothing
    false
  end

  ## identifier classes which should not be visible to the end user (i.e. which are automatically managed)
  ## should override this to return false
  def self.is_visible
    true
  end

  ## get a link to the catalog for this identifier
  def get_catalog_link
    NumbersRDF::NumbersHelper.identifier_to_url(name)
  end

  def get_hybrid(type = null)
    doc = REXML::Document.new content
    if (hybrid_idno = doc.elements["/TEI/teiHeader/fileDesc/publicationStmt/idno[@type='#{type ? "#{type}-" : ''}hybrid']"]) && hybrid_idno.text
      return hybrid_idno.text.to_s.strip
    end

    ''
  end
end
