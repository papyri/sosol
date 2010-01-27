class Publication < ActiveRecord::Base  
  validates_presence_of :title, :branch
  
  belongs_to :creator, :polymorphic => true
  belongs_to :owner, :polymorphic => true
  
  has_many :children, :class_name => 'Publication', :foreign_key => 'parent_id'
  belongs_to :parent, :class_name => 'Publication'
  
  has_many :identifiers, :dependent => :destroy
  has_many :events, :as => :target, :dependent => :destroy
 # has_many :votes, :dependent => :destroy
  has_many :comments
  
  validates_uniqueness_of :title, :scope => 'owner_id'
  validates_uniqueness_of :branch, :scope => 'owner_id'

  validates_each :branch do |model, attr, value|
    # Excerpted from git/refs.c:
    # Make sure "ref" is something reasonable to have under ".git/refs/";
    # We do not like it if:
    if value =~ /^\./ ||    # - any path component of it begins with ".", or
       value =~ /\.\./ ||   # - it has double dots "..", or
       value =~ /[~^: ]/ || # - it has [..], "~", "^", ":" or SP, anywhere, or
       value =~ /\/$/ ||    # - it ends with a "/".
       value =~ /\.lock$/   # - it ends with ".lock"
      model.errors.add(attr, "Branch \"#{value}\" contains illegal characters")
    end
    # not yet handling ASCII control characters
  end
  
  def populate_identifiers_from_identifier(identifier)
    self.title = identifier.tr(':','_')
    # Coming in from an identifier, build up a publication
    identifiers = NumbersRDF::NumbersHelper.identifiers_to_hash(
      NumbersRDF::NumbersHelper.identifier_to_identifiers(identifier))
    if identifiers.has_key?('ddbdp')
      identifiers['ddbdp'].each do |ddb|
        d = DDBIdentifier.new(:name => ddb)
        self.identifiers << d
        self.title = d.titleize
      end
    end
    
    # Use HGV hack for now
    if identifiers.has_key?('hgv') && identifiers.has_key?('trismegistos')
      identifiers['trismegistos'].each do |tm|
        tm_nr = NumbersRDF::NumbersHelper.identifier_to_components(tm).last
        self.identifiers << HGVMetaIdentifier.new(
          :name => "#{identifiers['hgv'].first}",
          :alternate_name => "hgv#{tm_nr}")
        
        # Check if there's a trans, if so, add it
        translation = HGVTransIdentifier.new(
          :name => "#{identifiers['hgv'].first}",
          :alternate_name => "hgv#{tm_nr}"
        )
        if !(Repository.new.get_file_from_branch(translation.to_path).nil?)
          self.identifiers << translation
        end
      end
    end
  end
  
  # If branch hasn't been specified, create it from the title before
  # validation, replacing spaces with underscore.
  # TODO: do a branch rename inside before_validation_on_update?
  def before_validation
    self.branch ||= title_to_ref(self.title)
  end
  
  
  def submit_to_next_board
    #horrible hack here to specifiy board order, change later with workflow engine
    #1 meta
    #2 transcription
    #3 translation    

    # find all unsubmitted meta ids, then text ids, then translation ids
    [HGVMetaIdentifier, DDBIdentifier, HGVTransIdentifier].each do |ic|
      identifiers.each do |i|
        if i.modified? && i.class == ic &&  i.status == "editing"
          #submit it
          submit_identifier(i)
          return
        end
      end
    end
  end
  
  def submit_identifier(identifier)
    #find correct board
    
    boards = Board.find(:all)
    boards.each do |board|
    if board.identifier_classes && board.identifier_classes.include?(identifier.class.to_s)
      
      copy_to_owner(board)
      # duplicate = self.clone
      #duplicate.owner = new_owner
     # duplicate.creator = self.creator
   #   duplicate.title = self.owner.name + "/" + self.title
   #   duplicate.branch = title_to_ref(duplicate.title)
        
      
      # self.owner_id = board.id
      # self.owner_type = "Board"
      
      identifier.status = "submitted"
      self.status = "submitted"
      
      
      # self.title = self.creator.name + "/" + self.title
      # self.branch = title_to_ref(self.title)
      # 
      # self.owner.repository.copy_branch_from_repo( duplicate.branch, self.branch, duplicate.owner.repository )
    #(from_branch, to_branch, from_repo)
      self.save
      identifier.save
      return
      end
    end
      
  end
  
  def submit
    submit_to_next_board
    return
    #note return here to comment out rest of function
    boards = Board.find(:all)
    boards.each do |board|
      board_matches_publication = false
      identifiers.each do |identifier|
        if !board.identifier_classes.nil? && board.identifier_classes.include?(identifier.class.to_s)
          board_matches_publication = true
          break
        end
      end
      
      if board_matches_publication
        copy_to_owner(board)
      end
    end
    
    self.status = "submitted"
    self.save!
    
    e = Event.new
    e.category = "submitted"
    e.target = self
    e.owner = self.owner
    e.save!
  end
  
  def self.new_from_templates(creator)
    new_publication = Publication.new(:owner => creator, :creator => creator)
    
    # fetch a title without creating from template
    new_publication.title = DDBIdentifier.new(:name => DDBIdentifier.next_temporary_identifier).titleize
    
    new_publication.status = "new"
    
    new_publication.save!
    
    # branch from master so we aren't just creating an empty branch
    new_publication.branch_from_master
    
    # create the two required identifier classes from templates
    new_ddb = DDBIdentifier.new_from_template(new_publication)
    new_hgv_meta = HGVMetaIdentifier.new_from_template(new_publication)
    
    # go ahead and create the third so we can get rid of the create button
    new_hgv_trans = HGVTransIdentifier.new_from_template(new_publication)
    
    
    return new_publication
  end
  
  def modified?
    
    retval = false
    self.identifiers.each do |i|
      retval = retval || i.modified?
    end
    
    retval
  end 
  
  def mutable?
    if self.status == "submitted"
      return false
    else
      return true
    end
  end
  
  # TODO: rename actual branch after branch attribute rename
  def after_create
  end
  
  def tally_votes(user_votes = nil)
    user_votes ||= self.votes
    
    # @comment = Comment.new()
    # @comment.article_id = params[:id]
    # @comment.text = params[:comment]
    # @comment.user_id = @current_user.id
    # @comment.reason = "vote"
    # @comment.save
    
    #TODO tie vote and comment together?  
    
    #need to tally votes and see if any action will take place
    decree_action = self.owner.tally_votes(user_votes)
    #arrrggg status vs action....could assume that voting will only take place if status is submitted, but that will limit our workflow options?
    #NOTE here are the types of actions for the voting results
    #approve, reject, graffiti
    
    # create an event if anything happened
    if !decree_action.nil? && decree_action != ''
      e = Event.new
      e.owner = self.owner
      e.target = self
      e.category = "marked as \"#{decree_action}\""
      e.save!
    end
  
  
    if decree_action == "approve"
      #@publication.get_category_obj().approve
      self.status = "approved"
      self.save
      self.send_to_finalizer
      # self.commit_to_canon
      # @publication.send_status_emails(decree_action)    
    elsif decree_action == "reject"
      #@publication.get_category_obj().reject       
      self.status = "editing" #reset to unsubmitted       
      self.save
      # @publication.send_status_emails(decree_action)
    elsif decree_action == "graffiti"               
      # @publication.send_status_emails(decree_action)
      #do destroy after email since the email may need info in the artice
      #@publication.get_category_obj().graffiti
      self.destroy #need to destroy related?
      # redirect_to url_for(dashboard)
    else
      #unknown action or no action    
    end
    
    return decree_action
  end
  
  def flatten_commits(finalizing_publication, finalizer, board_members)
    finalizing_publication.repository.fetch_objects(self.repository)
    
    # flatten commits by original publication creator
    # - use the submission reason as the main comment
    # - concatenate all non-empty commit messages into a list
    # - write a 'Signed-off-by:' line for each Ed. Board member
    # - rewrite the committer to the finalizer
    # - parent will be the branch point from canon (merge-base)
    # - tree will be from creator's last commit
    # - see http://idp.atlantides.org/trac/idp/wiki/SoSOL/Attribution
    # X insert a change in the XML revisionDesc header
    #   should instead happen at submit so EB sees it?
    
    canon_branch_point = self.merge_base
    # this relies on the parent being a remote, e.g. fetch_objects being used
    # during branch copy
    # board_branch_point = self.merge_base(
    #   [self.parent.repository.name, self.parent.branch].join('/'))
    # this works regardless
    board_branch_point = self.origin.head
    
    creator_commits = self.repository.repo.commits_between(canon_branch_point,
                                                           board_branch_point)
    board_commits = self.repository.repo.commits_between(board_branch_point,
                                                         self.head)
    
    creator_commit_messages = [self.submission_reason.comment, '']
    creator_commits.each do |creator_commit|
      message = creator_commit.message.strip
      unless message.empty?
        creator_commit_messages << " - #{message}"
      end
    end
    
    signed_off_messages = []
    board_members.each do |board_member|
      signed_off_messages << "Signed-off-by: #{board_member.author_string}"
    end
    
    commit_message =
      (creator_commit_messages + [''] + signed_off_messages).join("\n").chomp
    
    parent_commit = canon_branch_point
    tree_sha1 = self.repository.repo.commit(board_branch_point).tree.id
    contents = []
    contents << ['tree', tree_sha1].join(' ')
    contents << ['parent', parent_commit].join(' ')
    
    contents << ['author', self.creator.git_author_string].join(' ')
    contents << ['committer', finalizer.git_author_string].join(' ')
    contents << ''
    contents << commit_message
    
    flattened_commit_sha1 = 
      finalizing_publication.repository.repo.git.put_raw_object(
        contents.join("\n"), 'commit')
    
    finalizing_publication.repository.create_branch(
      finalizing_publication.branch, flattened_commit_sha1)
    
    # rewrite commits by EB
    # - write a 'Signed-off-by:' line for each Ed. Board member
    # - rewrite the committer to the finalizer
    # - change parent lineage to flattened commits
  end
  
  def send_to_finalizer
    board_members = self.owner.users
    
    # just select a random board member to be the finalizer
    finalizer = board_members[rand(board_members.length)]
    
    # finalizing_publication = copy_to_owner(finalizer)
    finalizing_publication = clone_to_owner(finalizer)
    self.flatten_commits(finalizing_publication, finalizer, board_members)
    
    finalizing_publication.status = 'finalizing'
    finalizing_publication.save!
  end
  
  def head
    self.owner.repository.repo.get_head(self.branch).commit.sha
  end
  
  def merge_base(branch = 'master')
    self.owner.repository.repo.git.merge_base({},branch,self.head).chomp
  end
  
  def commit_to_canon
    canon = Repository.new
    publication_sha = self.head
    canonical_sha = canon.repo.get_head('master').commit.sha
    
    # FIXME: This walks the whole rev list, should maybe use git merge-base
    # to find the branch point? Though that may do the same internally...
    # commits = canon.repo.commit_deltas_from(self.owner.repository.repo, 'master', self.branch)
    
    # canon.repo.git.merge({:no_commit => true, :stat => true},
      # self.owner.repository.repo.get_head(self.branch).commit.sha)
    
    # get the result of merging canon master into this branch
    merge = Grit::Merge.new(
      self.owner.repository.repo.git.merge_tree({},
        publication_sha, canonical_sha, publication_sha))
    
    if merge.conflicts == 0
      if merge.sections == 0
        # nothing new from canon, trivial merge by updating HEAD
        canon.add_alternates(self.owner.repository)
        canon.repo.update_ref('master', publication_sha)
        self.status = 'committed'
        self.save!
      end
    end
  end
  
  def branch_from_master
    owner.repository.create_branch(branch)
  end
  
  def controlled_identifiers
    if self.owner.class == Board
      return self.identifiers.select do |i|
        self.owner.identifier_classes.include?(i.class.to_s)
      end
    else
      return []
    end
  end
  
  def controlled_paths
    self.controlled_identifiers.collect do |i|
      i.to_path
    end
  end
  
  def diff_from_canon
    canon = Repository.new
    canonical_sha = canon.repo.get_head('master').commit.sha
    self.owner.repository.repo.git.diff(
      {:unified => 5000}, canonical_sha, self.head)
  end
  
  def submission_reason
    reason = Comment.find_by_publication_id(self.origin.id,
      :conditions => "reason = 'submit'")
  end
  
  def origin
    # walk the parent list until we encounter one with no parent
    origin_publication = self
    while (origin_publication.parent != nil) do
      origin_publication = origin_publication.parent
    end
    return origin_publication
  end
  
  def clone_to_owner(new_owner)
    duplicate = self.clone
    duplicate.owner = new_owner
    duplicate.creator = self.creator
    duplicate.title = self.owner.name + "/" + self.title
    duplicate.branch = title_to_ref(duplicate.title)
    duplicate.parent = self
    duplicate.save!
    
    # copy identifiers over to new pub
    identifiers.each do |identifier|
      duplicate_identifier = identifier.clone
      duplicate_identifier.parent = identifier
      duplicate.identifiers << duplicate_identifier
    end
    
    return duplicate
  end
  
  def repository
    return self.owner.repository
  end
  
  #copies this publication's branch to the new_owner's branch
  #returns duplicate publication with new_owner
  def copy_to_owner(new_owner)
    duplicate = self.clone_to_owner(new_owner)
    
    duplicate.owner.repository.copy_branch_from_repo(
      self.branch, duplicate.branch, self.owner.repository
    )
    
    return duplicate
  end
  
  # TODO: destroy branch on publication destroy
  
  # entry point identifier to use when we're just coming in from a publication
  def entry_identifier
    identifiers.first
  end
  
  protected
    def title_to_ref(str)
      str.tr(' ','_')
    end
end
