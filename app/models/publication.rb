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

    #find all unsubmitted meta ids
    identifiers.each do |i|
      if i.modified? && i.class.to_s == "HGVMetaIdentifier"  &&  i.status == "editing"
        #submit it
        submit_identifier(i)
        return
      end
    end
    
    #find all unsubmitted text ids
    identifiers.each do |i|
      if i.modified? && i.class.to_s == "DDBIdentifier"  &&  i.status == "editing"
        #submit it
        submit_identifier(i)
        return 
      end
    end
    
    #find all unsubmitted translation ids
    identifiers.each do |i|
      if i.modified? && i.class.to_s == "HGVTransIdentifier"  &&  i.status == "editing"
        #submit it
        submit_identifier(i)
        return
      end
    end  
  
  end
  
  def submit_identifier(identifier)
    #find correct board
    
    boards = Board.find(:all)
    boards.each do |board|
    if !board.identifier_classes.nil? && board.identifier_classes.include?(identifier.class.to_s)

      duplicate = self.clone
      #duplicate.owner = new_owner
     # duplicate.creator = self.creator
   #   duplicate.title = self.owner.name + "/" + self.title
   #   duplicate.branch = title_to_ref(duplicate.title)
        
      
      self.owner_id = board.id
      self.owner_type = "Board"
      
      identifier.status = "submitted"
      self.status = "submitted"
      
      
      self.title = self.creator.name + "/" + self.title      
      self.branch = title_to_ref(self.title)
      
      self.owner.repository.copy_branch_from_repo( duplicate.branch, self.branch, duplicate.owner.repository )
    #(from_branch, to_branch, from_repo)
      self.save
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
    
    new_publication.save!
    
    # branch from master so we aren't just creating an empty branch
    new_publication.branch_from_master
    
    # create the two required identifier classes from templates
    new_ddb = DDBIdentifier.new_from_template(new_publication)
    new_hgv_meta = HGVMetaIdentifier.new_from_template(new_publication)
    
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
  
  def tally_votes
    # @comment = Comment.new()
    # @comment.article_id = params[:id]
    # @comment.text = params[:comment]
    # @comment.user_id = @current_user.id
    # @comment.reason = "vote"
    # @comment.save
    
    #TODO tie vote and comment together?  
    
    #need to tally votes and see if any action will take place
    decree_action = self.owner.tally_votes(self.votes)
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
      self.status = "new" #reset to unsubmitted       
      self.save
      # @publication.send_status_emails(decree_action)
    elsif decree_action == "graffiti"               
      # @publication.send_status_emails(decree_action)
      #do destroy after email since the email may need info in the artice
      #@publication.get_category_obj().graffiti
      self.destroy #need to destroy related?
      # redirect_to url_for(dashboard)
      return
    else
      #unknown action or no action    
    end
  end
  
  def send_to_finalizer
    board_members = self.owner.users
    # just select a random board member to be the finalizer
    finalizer = board_members[rand(board_members.length)]
    
    finalizing_publication = copy_to_owner(finalizer)
    
    finalizing_publication.status = 'finalizing'
    finalizing_publication.save!
  end
  
  def head
    self.owner.repository.repo.get_head(self.branch).commit.sha
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
  
  def diff_from_canon
    canon = Repository.new
    canonical_sha = canon.repo.get_head('master').commit.sha
    self.owner.repository.repo.git.diff(
      {:unified => 5000}, canonical_sha, self.head)
  end
  
  def copy_to_owner(new_owner)
    duplicate = self.clone
    duplicate.owner = new_owner
    duplicate.creator = self.creator
    duplicate.title = self.owner.name + "/" + self.title
    duplicate.branch = title_to_ref(duplicate.title)
    duplicate.parent = self
    duplicate.save!
    
    # copy identifiers over to new pub
    identifiers.each do |identifier|
      duplicate_identifer = identifier.clone
      duplicate.identifiers << duplicate_identifer
    end
    
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
