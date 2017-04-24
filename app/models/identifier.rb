# - Super-class of all identifiers
class Identifier < ActiveRecord::Base

  include Swagger::Blocks

  swagger_schema :Identifier do
    key :required, [:id, :type]
    property :id do
      key :type, :integer
      key :format, :int64
    end
    property :type do
      key :type, :string
    end
    property :mimetype do
      key :type, :string
    end
    property :content do 
      key :type, :string
    end
    property :publication do
      key :type, :integer
      key :format, :int64
    end
    property :publication_community_name do
      key :type, :string
    end
  end

  IDENTIFIER_SUBCLASSES = Sosol::Application.config.site_identifiers.split(",")

  FRIENDLY_NAME = "Base Identifier"

  IDENTIFIER_STATUS = %w{ new editing submitted approved finalizing committed archived }

  validates_presence_of :name, :type

  belongs_to :publication

  #assume we want to delete the comments along with the identifier
  has_many :comments, :dependent => :destroy

  has_many :votes, :dependent => :destroy

  validates_each :type do |record, attr, value|
    record.errors.add attr, "Identifier must be one of #{Sosol::Application.config.site_identifiers}" unless Sosol::Application.config.site_identifiers.split(',').include?(value)
  end

  require 'jruby_xml'


  # - *Returns* :
  #   - all identifier classes enabled for the site
  def self.site_identifier_classes
    site_classes = []
    site_identifiers = Sosol::Application.config.site_identifiers.split(",")
    Identifier::IDENTIFIER_SUBCLASSES.each do |identifier_class|
        if site_identifiers.include?(identifier_class.to_s)
            site_classes << identifier_class
        end
    end
    return site_classes
  end

  # - *Returns* :
  #   - the originally created publication of this identifier (publciation that does not have a parent id)
  def origin
    self.publication.origin.identifiers.detect {|i| i.name == self.name && i.type == self.type}
  end

  # - *Returns* :
  #   - the parent publication of this identifier
  def parent
    self.publication.parent.identifiers.detect {|i| i.name == self.name && i.type == self.type}
  end

  # - *Returns* :
  #   - all the children of the publication that contains this identifier
  def children
    child_identifiers = []
    self.publication.children.each do |child_pub|
      child_identifiers << child_pub.identifiers.detect{|i| i.name == self.name && i.type == self.type}
    end
    return child_identifiers
  end

  # - *Returns* :
  #   - this idenfier's origin publication and the origin children, but not self
  def relatives
    if self.origin.nil?
      return []
    else
      return [self.origin] + self.origin.children - [self]
    end
  end

  # - *Returns* :
  #   - the repository for the owner of this identifier
  def repository
    return self.publication.nil? ? Repository.new() : self.publication.owner.repository
  end

  # - *Returns* :
  #   - the repository branch for this identifier
  def branch
    return self.publication.nil? ? 'master' : self.publication.branch
  end

  # - *Returns* :
  #   - the cotent of the file containing this identifier from the repository
  def content
    return self.repository.get_file_from_branch(
      self.to_path, self.branch)
  end

  # Validation of indentifier XML file against tei-epidoc.rng file
  # - *Args*  :
  #   - +content+ -> XML to validate if passed in, pulled from repository if not passed in
  # - *Returns* :
  #   - true/false
  def is_valid_xml?(content = nil)
    if content.nil?
      content = self.xml_content
    end
    self.class::XML_VALIDATOR.instance.validate(
      JRubyXML.input_source_from_string(content))
  end

  # Put stuff in here you want to do do all identifiers before a commit is done
  # - currently no logic is in here - just returns whatever was passed in
  # - intended to be overridden by Identifier subclasses, if necessary
  def before_commit(content)
    return content
  end

  # Commits identifier XML to the repository
  # - *Args*  :
  #   - +content+ -> the XML you want committed to the repository
  #   - +options+ -> hash of options to pass to repository (ex. - :comment, :actor)
  # - *Returns* :
  #   - a String of the SHA1 of the commit
  def set_content(content, options = {})
    default_actor = nil
    if((!self.owner.nil?) && (self.owner.class == User))
      default_actor = self.owner.jgit_actor
    end
      
    options.reverse_merge!(
      :comment => '',
      :actor    => default_actor)
    commit_sha = self.repository.commit_content(self.to_path,
                                   self.branch,
                                   content,
                                   options[:comment],
                                   options[:actor])
    self.modified = true
    self.save! unless self.id.nil?

    self.publication.update_attribute(:updated_at, Time.now) unless self.publication.nil?

    return commit_sha
  end

  # Retrieve the commits made to a file in the repository
  # - *Returns* :
  #   - array of commits
  def get_commits(max=10)
    # hack fix this to get 10 commits unti we can merge 
    # https://github.com/sosol/sosol/issues/81
    self.repository.get_log_for_file_from_branch(
        self.to_path, self.branch, max
    )
  end

  # Parse out most recent sha from log
  # - *Returns* :
  #   - id of latest commit as a string
  def get_recent_commit_sha
    commits = get_commits
    if commits && commits.length > 0
      return commits[0][:id].to_s
    end
    return ""
  end

  # Create consistent title for identifiers
  # - *Returns* :
  #   - title of identifier
  def titleize
    title = nil
    if self.class == HGVMetaIdentifier
      title = NumbersRDF::NumbersHelper::identifier_to_title(self.name)
    elsif self.class == HGVTransIdentifier
      title = NumbersRDF::NumbersHelper::identifier_to_title(
        self.name.sub(/trans/,''))
    elsif self.class == APISIdentifier
      title = self.name.split('/').last
    end

    if title.nil?
      if (self.class == DDBIdentifier) || (self.name =~ /#{self.class::TEMPORARY_COLLECTION}/)
        collection_name, volume_number, document_number =
          self.to_components.last.split(';')
        #puts "#{collection_name}, #{volume_number}, #{document_number}"
        collection_name =
          self.class.collection_names_hash[collection_name]

        # strip leading zeros
        document_number.sub!(/^0*/,'')

        if collection_name.nil?
          title = self.name.split('/').last
        else
          title =
           [collection_name, volume_number, document_number].reject{|i| i.blank?}.join(' ')
         end

         if self.respond_to?("is_reprinted?") && self.is_reprinted?
           title += " (reprinted)"
         end
      else # HGV with no name
        title =  [self.class::FRIENDLY_NAME, self.name.split('/').last.tr(';',' ')].join(' ')
      end
    end
    return title
  end

  # Splits out identifier file path from the identifier model name field into the separate components
  # - *Returns* :
  #   - components
  def to_components
    trimmed_name = NumbersRDF::NumbersHelper::identifier_to_local_identifier(self.name)
    # trimmed_name.sub!(/^\/#{self.class::IDENTIFIER_NAMESPACE}\//,'')
    components = NumbersRDF::NumbersHelper::identifier_to_components(trimmed_name)
    components.map! {|c| c.to_s}

    return components
  end

  # Creates an array of all the collection names for the associated identifier class (HGV, DDB, APIS)
  # - *Returns* :
  #   - array of collection names
  def self.collection_names
    unless defined? @collection_names
      tries ||= 3
      begin
        parts = NumbersRDF::NumbersHelper::identifier_to_parts([NumbersRDF::NAMESPACE_IDENTIFIER, self::IDENTIFIER_NAMESPACE].join('/'))
        raise NumbersRDF::Timeout if parts.nil?
        @collection_names = parts.collect {|p| NumbersRDF::NumbersHelper::identifier_to_components(p).last}
      rescue NumbersRDF::Timeout => e
        Rails.logger.error "NumbersRDF::Timeout constructing collection names for #{self::IDENTIFIER_NAMESPACE}"
        if (tries -= 1) > 0
          retry
        else
          raise e
        end
      end
    end
    return @collection_names
  end

  # Create default XML file and identifier model entry for associated identifier class
  # - *Args*  :
  #   - +publication+ -> the publication the new translation is a part of
  #   - +allow_multiple+ -> flag to indicate if multiple identifiers of this type are allowed on the publication
  # - *Returns* :
  #   - new identifier
  def self.new_from_template(publication, allow_multiple = false)
    new_identifier = self.new(:name => self.next_temporary_identifier)
    Identifier.transaction do
      publication.lock!
      if publication.identifiers.select{|i| i.class == self}.length > 0 && ! allow_multiple
        return nil
      else
        new_identifier.publication = publication
        new_identifier.save!
      end
    end

    initial_content = new_identifier.file_template
    new_identifier.set_content(initial_content, :comment => 'Created from SoSOL template', :actor => (publication.owner.class == User) ? publication.owner.jgit_actor : publication.creator.jgit_actor)

    return new_identifier
  end

  # Create file and identifier model entry for associated identifier class
  # from the supplied content
  # - *Args*  :
  #   - +publication+ -> the publication the new translation is a part of
  #   - +agent+ -> String URI identifying the source of the content
  #   - +content+ -> the content
  #   - +comment+ -> a commit comment
  # - *Returns* :
  #   - new identifier
  def self.new_from_supplied(publication,agent,content,comment)
    id,updated_content = self.identifier_from_content(agent,content)
    new_identifier = self.new(:name => id)
    # don't try to create an identifier from invalid content
    unless new_identifier.is_valid_xml?(updated_content)
      raise Exception.new("Invalid content")
    end
    Identifier.transaction do
      publication.lock!
      if publication.identifiers.select{|i| i.class == self}.length > 0
        return nil
    else
      new_identifier.publication = publication
      new_identifier.save!
    end
  end

    new_identifier.set_content(updated_content, :comment => comment, :actor => (publication.owner.class == User) ? publication.owner.jgit_actor : publication.creator.jgit_actor)
    template_init = new_identifier.add_change_desc(comment)
    new_identifier.set_xml_content(template_init, :comment => 'Initializing Content')
    return new_identifier
  end

  # Processes ERB file from retrieved default XML file template for the associated identifier class
  # in data/templates/
  # - *Returns* :
  #   - evaluated file template as string
  def file_template
    template_path = File.join(Rails.root, ['data','templates'],
                              "#{self.class.to_s.underscore}.xml.erb")

    template = ERB.new(File.new(template_path).read, nil, '-')

    id = self.id_attribute
    n = self.n_attribute
    title = self.xml_title_text

    return template.result(binding)
  end

  # Determines the next 'SoSOL' temporary name for the associated identifier
  # - starts at '1' each year
  # - *Returns* :
  #   - temporary identifier name
  def self.next_temporary_identifier
    year = Time.now.year
    latest = self.find(:all,
                       :conditions => ["name like ?", "papyri.info/#{self::IDENTIFIER_NAMESPACE}/#{self::TEMPORARY_COLLECTION};#{year};%"],
                       :order => "name DESC",
                       :limit => 1).first
    if latest.nil?
      # no constructed id's for this year/class
      document_number = 1
    else
      document_number = latest.to_components.last.split(';').last.to_i + 1
    end

    return sprintf("papyri.info/#{self::IDENTIFIER_NAMESPACE}/#{self::TEMPORARY_COLLECTION};%04d;%04d",
                   year, document_number)
  end

  # Method which can use uses supplied content to determine the associated identifier name
  # - *Args* :
  #   - +agent+ -> the source of the content
  #   - +content+ -> the content
  # - *Returns* :
  #   - identifier name and the content (it may have been updated)
  def self.identifier_from_content(agent,content)
    # Identifier specific functionality
    # Default behavior is to just defer to next_tempoary_identifier
    return self.next_temporary_identifier, content
  end

  # Determines the user who own's this identifer based on the publication it is a part of
  # - *Returns* :
  #   - identifier owner
  def owner
    if !self.publication.nil?
      return self.publication.owner
    else
      return nil
    end
  end

  # Determines who can edit the identifier
  # - owner can edit any of their stuff if it is not submitted
  # - only let the board edit if they own it
  # - let the finalizer edit the identifier the board owns
  #
  # - *Returns* :
  #   - true/false
  def mutable?

    #only let the board edit if they own it
    if self.publication.owner_type == "Board" && self.publication.status == "editing"
      if self.publication.owner.identifier_classes.include?(self.class.to_s)
       return true
      end

    #let the finalizer edit the id the board owns
    elsif self.publication.status == "finalizing" &&  self.publication.find_first_board.identifier_classes.include?(self.class.to_s)
      return true

    #they can edit any of their stuff if it is not submitted
    elsif self.publication.owner_type == "User" && %w{editing new}.include?(self.publication.status)
      return true
    end

    return false

  end
  
  # - *Returns* :
  #   - the content of the associated identifier's XML file
  def xml_content
    return self.content
  end

  # Commits identifier XML to the repository vis set_content
  # - *Args*  :
  #   - +content+ -> the XML you want committed to the repository
  #   - +options+ -> hash of options to pass to repository (ex. - :comment, :actor)
  # - *Returns* :
  #   - a String of the SHA1 of the commit
  def set_xml_content(content, options)
    default_actor = nil
    if((!self.owner.nil?) && (self.owner.class == User))
      default_actor = self.owner.jgit_actor
    end

    options.reverse_merge!(
      :validate => true,
      :actor    => default_actor)

    content = before_commit(content)
    commit_sha = ""
    if options[:validate] && is_valid_xml?(content)
      commit_sha = self.set_content(content, options)
    end

    # this is a little bit of a hack -- if the before_commit
    # call stores a postcommit version of the content then we
    # do a 2nd commit so that we have a full history of the changes
    # in the commit history
    if self[:postcommit]  
      if (! options[:validate] || is_valid_xml?(self[:postcommit]))
        options[:comment] = self[:transform_messages].join(' ')
        commit_sha = self.set_content(self[:postcommit], options)
      end
    end
    
    return commit_sha
  end

  # Used to rename an identifier from the 'SoSOL' temporary name to the correct 'collection' name
  # - also renames and 'relatives' of the identifier
  # - *Args*  :
  #   - +new_name+ -> name the finalizer has provided
  #   - +options+ -> hash of options to pass to repository (ex. - :comment, :actor)
  # - *Returns* :
  #   - a String of the SHA1 of the commit
  def rename(new_name, options = {})
    original = self.dup
    options[:original] = original

    original_name = self.name
    original_path = self.to_path
    original_relatives = self.relatives

    self.transaction do
      self.name = new_name
      self.title = self.titleize
      self.save!

      new_path = self.to_path
      commit_message = "Rename #{self.class::FRIENDLY_NAME} from '#{original_name}' (#{original_path}) to '#{new_name}' (#{new_path})"

      self.repository.rename_file(original_path,
                                  new_path,
                                  self.branch,
                                  commit_message,
                                  self.owner.jgit_actor)

      # rename origin and children
      original_relatives.each do |relative|
        relative.name = new_name
        relative.title = self.title
        relative.save!

        # rename the file on the relative
        relative.repository.rename_file(original_path,
                                        new_path,
                                        relative.branch,
                                        commit_message,
                                        self.owner.jgit_actor)
      end
      self.after_rename(options)
    end
  end

  # Place anything actions you need performed on all identifiers after a 'rename' has occurred
  # - nothin in here at this time
  def after_rename(options = {})
  end

  # Determines if identifier is in a temporary collection and so needs renaming before finalization.
  # - *Returns* :
  #   - true/false
  def needs_rename?
    if defined?(self.class::TEMPORARY_COLLECTION)
      if self.to_components[2] =~ /^#{self.class::TEMPORARY_COLLECTION}[.;\/]/
        return true
      end
    end
    return false
  end

  # Added to speed up dashboard since titleize can be slow
  # - gets the title from the identifier model if it exists, otherwise creates it using titleize and saves
  #   it in the model
  # - *Returns* :
  #   - title from identifer model
  def title
    if read_attribute(:title).blank?
      # because this might be called when intended to read only, a failure to save a title 
      # shouldn't raise a fatal error here - instead flag the identifier as invalid by its title
      begin
          new_title = self.titleize
      rescue  Exception => e
          Rails.logger.error(e.backtrace)
          Rails.logger.error("Error titleizing identifier #{self.inspect}")
          new_title = "Invalid Identifier"
      end
      write_attribute(:title,new_title)
      self.save
    end
    return read_attribute(:title)
  end

  # Add a 'change' tag into the tei:revisionDesc of the identifer's XML file via XSLT
  # - does not do a commit - just modifies XML and returns it
  # - *Args*  :
  #   - +text+ -> the comment the user/system has provided
  #   - +user_info+ ->  used in the 'who' attribute of the 'change' tag if give, otherwise uses the publications creator
  #   - +input_content+ -> the XML you want this added to, otherwise pulls it from the repository for this identifier
  # - *Returns* :
  #   - string of the XML containing the added 'change' tag
  def add_change_desc(text = "", user_info = self.publication.creator, input_content = nil, timestamp = Time.now.xmlschema)
    doc = JRubyXML.apply_xsl_transform(
      JRubyXML.stream_from_string(input_content.nil? ? self.xml_content : input_content),
      JRubyXML.stream_from_file(File.join(Rails.root,
        %w{data xslt common add_change.xsl})),
      :who => "#{Sosol::Application.config.site_user_namespace}#{URI.escape(user_info.name)}",
      :comment => text,
      :when => timestamp
    )

    return doc.to_s
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
    change_desc_content = self.xml_content

    # assume context is from finalizing publication, so parent is board's copy
    if self.parent
      parent_classes = self.parent.owner.identifier_classes
    else
      # if we created upon finalization we won't have a parent...
      parent_classes = []
    end  
    
    Comment.find_all_by_publication_id(self.publication.origin.id).each do |c|
      if(parent_classes.include?(c.identifier.class.to_s))
        change_desc_content = add_change_desc( "#{c.reason.capitalize} - " + c.comment, c.user, change_desc_content, c.created_at.localtime.xmlschema )
        commit_message += " - #{c.reason.capitalize} - #{c.comment} (#{c.user.human_name})\n"
      end
    end

    change_desc_content = add_change_desc( "Finalized - " + comment_text, user, change_desc_content)
    commit_message += " - Finalized - #{comment_text} (#{user.human_name})"

    self.set_xml_content(change_desc_content, :comment => commit_message)
  end

  # See documentation of result_actions method of board model
  def result_action_approve

    self.status = "approved"
    self.publication.send_to_finalizer
  end

  # See documentation of result_actions method of board model
  def result_action_reject

    self.status = "rejected"
  end

  # See documentation of result_actions method of board model
  def result_action_graffiti

    #delete
  end

  # Determines if identifier in board members dashboard needs reviewing by that member
  # - *Returns*
  #   - +true+ if the identifier needs reviewing
  #   - +false+ if does not need reviewing
  def needs_reviewing?(user_id)
    return self.modified? && self.publication.status == "voting" && self.publication.owner_type == "Board" && self.publication.owner.controls_identifier?(self) && !self.publication.user_has_voted?(user_id) #!self.user_has_voted?(user_id)
  end

  # Determines whether a specified user has voted on this identifier or not
  # - *Args*  :
  #   - +user_id+ -> the id of the user checking to see if voted or not
  # - *Returns* :
  #   - true/false
  def user_has_voted?(user_id)
    if self.votes
      self.votes.each do |vote|
        if vote.user_id == user_id
          return true #user has a vote on record for this identifier
        end
      end
    end
    #no vote found
    return false
  end
  
  ## identifier classes which need further automatic processing after 
  ## approval but before finalization should override this method -- 
  ## the default does nothing
  ## @param reviewed_by set to a list of author strings for the board
  ##        members of the finalizing board
  def preprocess_for_finalization(reviewed_by)
    # default does nothing
    return false
  end

  ## identifier classes which should not be visible to the end user (i.e. which are automatically managed)
  ## should override this to return false
  def self.is_visible
    return true
  end

  ## get a link to the catalog for this identifier
  def get_catalog_link
    [Sosol::Application.config.site_catalog_search, NumbersRDF::NumbersHelper.identifier_to_url(self.name)]
  end
  
  ## create a default title for an identifier
  ## @param a_from is up to the controller
  def self.create_title(a_from)
    ## default just returns the passed string
    return a_from
  end

  def download_file_name
   # default 
   self.class::FRIENDLY_NAME + "-" + self.title.gsub(/\s/,'_') + ".xml"
  end

  # patch identifier content - possibly from an external agent
  # - +Args+ :
  #  - +a_agent+ -> String URI identifying source of the updated content
  #  - +a_query+ -> String identifier specific query to identify fragment to update
  #  - +a_content+ -> The content fragment
  #  - +a_commment+ -> Commit comment
  def patch_content(a_agent,a_query,a_content,a_comment)
    raise Exception.new("patch not implemented for #{self.class.name}")
  end

  # return a fragment of the content as requested by the supplied query
  # which is specified in an identifier-specific manner
  # - *Args* :
  #   - +a_query+ -> Query String
  # - *Returns* :
  #   - the requested fragment as a String or Nil if not found
  def fragment(a_query)
    raise Exception.new("get_fragment not implemented for #{self.class.name}")
  end

  # Looks for active identifiers that named like supplied name
  # - *Args*  :
  #   - +match_id+ -> the name of the identifier we are trying to match
  #   - +match_user+ -> the User owner we are trying to match
  #   - +match_callback+ -> Callback function which receives the potentially matching
  #                         identifier and returns true if it matches, false if not
  # - *Returns* :
  #   - array of matching identifiers
  def self.find_like_identifiers(match_id,match_user,match_callback)
    identifiers = []
    possible_conflicts = self.find(:all,
                       :conditions => ["name like ?", "#{match_id}%"],
                       :order => "name DESC")
    actual_conflicts = possible_conflicts.select {|pc|
      ( (pc.publication) &&
        (pc.publication.owner == match_user) &&
        !(%w{archived finalized}.include?(pc.publication.status)) &&
        match_callback.call(pc)
       )
     }
    identifiers += actual_conflicts
    return identifiers
  end

  # return a poth to this identifier for use in a remote repository
  # - *Returns% :
  #   - a path to use to store the file on a remote repo
  def to_remote_path
    # by default we will just use the local path
    # to override by identifier type
    self.to_path
  end

  # return the schema of the identifier content
  # - *Returns* :
  #   - the schema of the identifier content
  def schema
    ''
  end

  # return the mimetype of the identifier content
  # - *Returns* :
  #   - the mimetype of the identifier content
  def mimetype
    "application/xml"
  end

  # describe the identifier as data object in a 
  # downloadable Research Object Bundle
  # by default it just gets put in the data folder
  def as_ro
    ro = { 'annotations' => [], 'aggregates' => [] } 
    about = []
    aggregates = []
    package_obj = {
      'conformsTo' => self.schema,
      'mediatype' => self.mimetype,
      'createdBy' => { 'name' => self.publication.creator.full_name, 'uri' => self.publication.creator.uri }
    }
    package_obj['uri'] = File.join('../data',self.download_file_name)
    ro['aggregates'] << package_obj
    return ro
  end

end
