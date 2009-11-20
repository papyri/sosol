class Publication < ActiveRecord::Base  
  validates_presence_of :title, :branch
  
  belongs_to :creator, :polymorphic => true
  belongs_to :owner, :polymorphic => true
  has_many :identifiers, :dependent => :destroy
  has_many :events, :as => :target, :dependent => :destroy
  has_many :votes, :dependent => :destroy
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
  
  def submit
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
  
  def branch_from_master
    owner.repository.create_branch(branch)
  end
  
  def copy_to_owner(new_owner)
    duplicate = self.clone
    duplicate.owner = new_owner
    duplicate.creator = self.creator
    duplicate.title = self.owner.name + "/" + self.title
    duplicate.branch = title_to_ref(duplicate.title)
    duplicate.save!
    
    # copy identifiers over to new pub
    identifiers.each do |identifier|
      duplicate_identifer = identifier.clone
      duplicate.identifiers << duplicate_identifer
    end
    
    duplicate.owner.repository.copy_branch_from_repo(
      self.branch, duplicate.branch, self.owner.repository
    )
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
