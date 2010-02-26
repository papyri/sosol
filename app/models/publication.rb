class Publication < ActiveRecord::Base  
  
  PUBLICATION_STATUS = %w{ new editing submitted approved finalizing committed archived }
  
  validates_presence_of :title, :branch
  
  belongs_to :creator, :polymorphic => true
  belongs_to :owner, :polymorphic => true
  
  has_many :children, :class_name => 'Publication', :foreign_key => 'parent_id'
  belongs_to :parent, :class_name => 'Publication'
  
  has_many :identifiers, :dependent => :destroy
  has_many :events, :as => :target, :dependent => :destroy
 # has_many :votes, :dependent => :destroy
  has_many :comments
  
  validates_uniqueness_of :title, :scope => [:owner_type, :owner_id]
  validates_uniqueness_of :branch, :scope => [:owner_type, :owner_id]

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
    self.title = identifier_to_ref(identifier)
    # Coming in from an identifier, build up a publication
    identifiers = NumbersRDF::NumbersHelper.identifiers_to_hash(
      NumbersRDF::NumbersHelper.identifier_to_identifiers(identifier))
      
    [DDBIdentifier, HGVMetaIdentifier, HGVTransIdentifier].each do |identifier_class|
      if identifiers.has_key?(identifier_class::IDENTIFIER_NAMESPACE)
        identifiers[identifier_class::IDENTIFIER_NAMESPACE].each do |identifier_string|
          temp_id = identifier_class.new(:name => identifier_string)
          self.identifiers << temp_id
          if self.title == identifier_to_ref(identifier)
            self.title = temp_id.titleize
          end
        end
      end
    end
    
    # Use HGV hack for now
    # if identifiers.has_key?('hgv') && identifiers.has_key?('trismegistos')
    #   identifiers['trismegistos'].each do |tm|
    #     tm_nr = NumbersRDF::NumbersHelper.identifier_to_components(tm).last
    #     self.identifiers << HGVMetaIdentifier.new(
    #       :name => "#{identifiers['hgv'].first}",
    #       :alternate_name => "hgv#{tm_nr}")
    #     
    #     # Check if there's a trans, if so, add it
    #     translation = HGVTransIdentifier.new(
    #       :name => "#{identifiers['hgv'].first}",
    #       :alternate_name => "hgv#{tm_nr}"
    #     )
    #     if !(Repository.new.get_file_from_branch(translation.to_path).nil?)
    #       self.identifiers << translation
    #     end
    #   end
    # end
  end
  
  # If branch hasn't been specified, create it from the title before
  # validation, replacing spaces with underscore.
  # TODO: do a branch rename inside before_validation_on_update?
  def before_validation
    self.branch ||= title_to_ref(self.title)
  end
  
  # Should check the owner's repo to make sure the branch doesn't exist and halt if so
  def before_create
    if self.owner.repository.branches.include?(self.branch)
      return false
    end
  end
  
  def after_destroy
    self.owner.repository.delete_branch(self.branch)
  end
  
  def submit_to_next_board
    #horrible hack here to specifiy board order, change later with workflow engine
    #1 meta
    #2 transcription
    #3 translation    
    error_text = ""
    # find all unsubmitted meta ids, then text ids, then translation ids
    [HGVMetaIdentifier, DDBIdentifier, HGVTransIdentifier].each do |ic|
      identifiers.each do |i|
        if i.modified? && i.class == ic &&  i.status == "editing"
          #submit it
          if submit_identifier(i)
            return
          else            
            error_text  += "no board for " + ic.to_s
            return #for now
          end
        end
      end
    end
    
    #if we get to this point, nothing else was submitted therefore we are done with publication
    #can this be reached without a commit actually taking place?
=begin
    if error_text != ""
      flash[:warning] = error_text
      # couldnt submit to non exiting board so send back to user?
      #TODO check this
      self.origin.status = "editing" 
      self.save
    end
=end
    self.origin.status = "committed" 
    self.save
    
  end
  
  def submit_identifier(identifier)
    #find correct board
    
    boards = Board.find(:all)
    boards.each do |board|
      if board.identifier_classes && board.identifier_classes.include?(identifier.class.to_s)
        
        boards_copy = copy_to_owner(board)
        boards_copy.status = "voting"
        boards_copy.save
        
        # duplicate = self.clone
        #duplicate.owner = new_owner
       # duplicate.creator = self.creator
     #   duplicate.title = self.owner.name + "/" + self.title
     #   duplicate.branch = title_to_ref(duplicate.title)
          
        
        # self.owner_id = board.id
        # self.owner_type = "Board"
        
        identifier.status = "submitted"
        self.status = "submitted"
        
        board.send_status_emails("submitted", self)
        
        # self.title = self.creator.name + "/" + self.title
        # self.branch = title_to_ref(self.title)
        # 
        # self.owner.repository.copy_branch_from_repo( duplicate.branch, self.branch, duplicate.owner.repository )
      #(from_branch, to_branch, from_repo)
        self.save
        identifier.save
        return true
      end
    end
    return false
  end
  
  def submit
    submit_to_next_board
    return
=begin
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
    
=end
    
  end
  
  def self.new_from_templates(creator)
    new_publication = Publication.new(:owner => creator, :creator => creator)
    
    # fetch a title without creating from template
    new_publication.title = DDBIdentifier.new(:name => DDBIdentifier.next_temporary_identifier).titleize
    
    new_publication.status = "new" #TODO add new flag else where or flesh out new status#"new"
    
    new_publication.save!
    
    # branch from master so we aren't just creating an empty branch
    new_publication.branch_from_master
            
    #create the required meta data and transcriptions
    new_ddb = DDBIdentifier.new_from_template(new_publication)      
    new_hgv_meta = HGVMetaIdentifier.new_from_template(new_publication)
            
    # go ahead and create the third so we can get rid of the create button
    #new_hgv_trans = HGVTransIdentifier.new_from_template(new_publication)    
    
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
    if self.status != "editing" # && self.status != "new"
      return false
    else
      return true
    end
  end
  

  # TODO: rename actual branch after branch attribute rename
  def after_create
  end
  
  #sets thes origin status for publication identifiers that the publication's board controls
  def set_origin_identifier_status(status_in)    

      #finalizer is a user so they dont have a board, must go up until we find a board
      
      board = self.find_first_board
      if board
              
        self.identifiers.each do |i|
          if board.identifier_classes && board.identifier_classes.include?(i.class.to_s)
            i.origin.status = status_in
            i.origin.save
          end
        end
        
      end
  end

  def set_local_identifier_status(status_in)   

      board = self.find_first_board
      if board
            
        self.identifiers.each do |i|
          if board.identifier_classes && board.identifier_classes.include?(i.class.to_s)
            i.status = status_in
            i.save
          end
        end
        
      end
  end

  def set_origin_and_local_identifier_status(status_in)
    set_origin_identifier_status(status_in)          
    set_local_identifier_status(status_in)          
  end

#needed to set the finalizer's board identifier status
  def set_board_identifier_status(status_in)
      pub = self.find_first_board_parent
      if pub            
        pub.identifiers.each do |i|
          if pub.owner.identifier_classes && pub.owner.identifier_classes.include?(i.class.to_s)
            i.status = status_in
            i.save
          end
        end
        
      end
  end
  
  def archive
    #delete the repo
    self.owner.repository.delete_branch(self.branch)
    #set status to archved
    self.status = "archived" 
    #should we set identifiers status as well?
    self.save  
  end
  
  def tally_votes(user_votes = nil)
    user_votes ||= self.votes
    
    #check that we are still taking votes
    if self.status != "voting"
      return "" #return nothing and do nothing since the voting is now over
    end
    
    #need to tally votes and see if any action will take place
    if self.owner_type != "Board" # || !self.owner #make sure board still exist...add error message?
      return "" #another check to make sure only the board is voting on its copy
    else
      decree_action = self.owner.tally_votes(user_votes)
    end
   
    
    # create an event if anything happened
    if !decree_action.nil? && decree_action != ''
      e = Event.new
      e.owner = self.owner
      e.target = self
      e.category = "marked as \"#{decree_action}\""
      e.save!
    end
  
    if decree_action == "approve"
      
      #set local publication status to approved
      self.status = "approved"
      self.save
      
      #on approval, set the identifier(s) to approved (local and origin)
      self.set_origin_and_local_identifier_status("approved")
      
      #send emails
       self.owner.send_status_emails("approved", self)
      # @publication.send_status_emails(decree_action)          
      
      #set up for finalizing
      self.send_to_finalizer
      
      
    elsif decree_action == "reject"
      #@publication.get_category_obj().reject       
     
      self.origin.status = "editing"
      self.set_origin_and_local_identifier_status("editing")
      
      self.owner.send_status_emails("rejected", self)
      
      #do we want to copy ours back to the user? yes
      #TODO test copy to user
      #WARNING since they decided not to let editors edit we don't need to copy back to user 1-28-2010
      #self.copy_repo_to_parent_repo
      
      self.origin.save
      
      #what to do with our copy?
     # self.status = "rejected" #reset to unsubmitted       
     # self.save
      
      self.destroy
      #redirect to dashboard
     # redirect_to ( dashboard_url )
     # redirect_to :controller => "user", :action => "dashboard"
      #TODO send status emails
      # @publication.send_status_emails(decree_action)
      
    elsif decree_action == "graffiti"               
      # @publication.send_status_emails(decree_action)
      #do destroy after email since the email may need info in the artice
      #@publication.get_category_obj().graffiti
      
      self.owner.send_status_emails("graffiti", self)
      #todo do we let one board destroy the entire document?
      #will this destroy all board copies....
      self.origin.destroy #need to destroy related? 
      self.destroy
     # redirect_to ( dashboard_url )
      #TODO we need to walk the tree and delete everything everywhere??
      #or
      #self.submit_to_next_board
      
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
    
    self.owner.repository.update_master_from_canonical
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
    
    reason_comment = self.submission_reason
    
    
    board_controlled_paths = self.controlled_paths
    Rails.logger.info("Controlled Paths: #{board_controlled_paths.inspect}")

    controlled_commits = creator_commits.select do |creator_commit|
      Rails.logger.info("Checking Creator Commit id: #{creator_commit.id}")
      controlled_commit_diffs = Grit::Commit.diff(self.repository.repo, creator_commit.parents.first.id, creator_commit.id, board_controlled_paths.clone)
      controlled_commit_diffs.length > 0
    end
    
    Rails.logger.info("Controlled Commits: #{controlled_commits.inspect}")
    
    creator_commit_messages = [reason_comment.nil? ? '' : reason_comment.comment, '']
    controlled_commits.each do |controlled_commit|
      message = controlled_commit.message.strip
      unless message.empty?
        creator_commit_messages << " - #{message}"
      end
    end
    
    controlled_blobs = board_controlled_paths.collect do |controlled_path|
      self.owner.repository.get_blob_from_branch(controlled_path, self.branch)
    end
    
    controlled_paths_blobs = 
      Hash[*((board_controlled_paths.zip(controlled_blobs)).flatten)]
    
    Rails.logger.info("Controlled Blobs: #{controlled_blobs.inspect}")
    Rails.logger.info("Controlled Paths => Blobs: #{controlled_paths_blobs.inspect}")
    
    signed_off_messages = []
    board_members.each do |board_member|
      signed_off_messages << "Signed-off-by: #{board_member.author_string}"
    end
    
    commit_message =
      (creator_commit_messages + [''] + signed_off_messages).join("\n").chomp
    
    # parent commit should ALWAYS be canonical master head
    # FIXME: handle racing during finalization
    parent_commit = Repository.new.repo.get_head('master').commit.sha
    # parent_commit = canon_branch_point
    
    # roll a tree SHA1 by reading the canonical master tree,
    # adding controlled path blobs, then writing the modified tree
    # (happens on the finalizer's repo)
    finalizer.repository.update_master_from_canonical
    index = finalizer.repository.repo.index
    index.read_tree('master')
    controlled_paths_blobs.each_pair do |path, blob|
      index.add(path, blob.data)
    end
    
    tree_sha1 = index.write_tree(index.tree, index.current_tree)
    Rails.logger.info("Wrote tree as SHA1: #{tree_sha1}")
    # tree_sha1 = self.repository.repo.commit(board_branch_point).tree.id
    
    # most of this is dup'd from Grit::Index#commit
    # with modifications to allow for correct timestamping
    # and author/committer split
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
  
  #finalizer is a user
  def send_to_finalizer(finalizer = nil)
    board_members = self.owner.users   
    if !finalizer
      #get someone from the board    
#      board_members = self.owner.users    
      # just select a random board member to be the finalizer
      finalizer = board_members[rand(board_members.length)]  
    end
      
    # finalizing_publication = copy_to_owner(finalizer)
    finalizing_publication = clone_to_owner(finalizer)
    self.flatten_commits(finalizing_publication, finalizer, board_members)
    
    #should we clear the modified flag so we can tell if the finalizer has done anything
    # that way we will know in the future if we can change finalizersedidd
    finalizing_publication.status = 'finalizing'
    finalizing_publication.save!
  end  
  
  def remove_finalizer
    #need to find out if there is a finalizer, and take the publication from them
    #finalizer will point back to this boards publication
   # Publication.existing_finalizer self.id
    current_finalizer_publication = find_finalizer_publication
    #delete him?
    #whatch out for cascading comment deltes...???TODO
    if current_finalizer_publication
      current_finalizer_publication.delete
    end
  
  end
  
  
  def find_finalizer_user
    if find_finalizer_publication
      return find_finalizer_publication.owner    
    end
    return nil
  end
  
  def find_finalizer_publication
  #returns the finalizer user or nil if finalizer does not exist
    Publication.find_by_parent_id( self.id, :conditions => { :status => "finalizing" })
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
        canon_sha = shacanon.repo.update_ref('master', publication_sha)
        self.status = 'committed'
        self.save!
        return canon_sha
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
  
  #finds the closest parent publication whose owner is a board and returns that board
  def find_first_board
    board_publication = self
    while (board_publication.owner_type != "Board" && board_publication != nil) do
      board_publication = board_publication.parent
    end
    if board_publication
      return board_publication.owner
    end
    return nil
  end
  
  #finds the closest parent publication whose owner is a board and returns that publication
  def find_first_board_parent
    board_publication = self
    while (board_publication.owner_type != "Board" && board_publication != nil) do
      board_publication = board_publication.parent
    end
    return board_publication      
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
    
  #copy a child publication repo back to the parent repo
  def copy_repo_to_parent_repo
     #all we need to do is copy the repo back the parents repo
     self.origin.repository.copy_branch_from_repo(self.branch, self.origin.branch, self.repository)
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
    
    def identifier_to_ref(str)
      str.tr(':;','_')
    end
end
