#Communities are designed to allow anyone to create their own set of boards and editorial review.
#The workflow and boards work the same as the standard SoSOL workflow with the exception that the finalized publications is not committed to canonical. Instead it is copied to the chosen end_user for the community.

class Community < ActiveRecord::Base
  
  has_many :communities_members
  has_many :members, :class_name => "User", :source => :user, :foreign_key => "community_id", :through => :communities_members
  has_many :communities_admins
  has_many :admins, :class_name => "User", :source => :user, :foreign_key => "community_id", :through => :communities_admins
  
  
  has_many :boards , :dependent => :destroy 
  has_many :publications
  
  validates_uniqueness_of :name, :case_sensitive => false
  validates_presence_of :name

  attr_protected :is_default

  validate :is_default_can_only_be_one

  before_destroy :guard_default


  # validates that we only set a single default community
  # is_default must be reset in a transaction which 
  # first removes the currnet default and then sets a new one
  def is_default_can_only_be_one
    if is_default? && ! Community.default.nil?
      errors.add(:is_default, "Can't have more than one default community")
      return false
    end
  end

  

  #Checks to see whether or not to allow members to submit to the community
  #
  #*Returns*
  #- true if the community is setup properly to receive submissions
  #- false if community should not be submitted to
  def is_submittable?
    #if there is nowhere for the final publication to go, don't let them submit
    #if there are no boards to review the publication, don't let them submit
    return self.boards && self.boards.length > 0
  end
  
  #*Returns* 
  #- a standard format for the community name and friendly_name.
  #Used to ensure consistency throughout pages.
  def format_name
    return  self.name + " ( " + self.friendly_name + " )"
  end

  #*Returns*
  # - the default Community
  def self.default
    self.where(["is_default = ?", true ]).first
  end

  #*Returns*
  # - changes the default community
  def self.change_default(new)
    old = self.default
    self.transaction do 
      old.is_default = false
      old.save!
      new.is_default = true 
      new.save!
    end
  end

  # Handles Promotion of a publication to the next 
  # step in the workflow after finalization
  #*Args*:
  #- +publication+ publication to be promoted
  def promote(publication)
    # override in subclasses to enable per community-type workflow
  end

 
  # Community-specific finalization steps
  # *Args*:
  #- +publication+ publication to be finalized
  # *Returns*
  # - a commit sha if any commit occurs, otherwise nil
  def finalize(publication)
    # default is a noop
    nil
  end

  # Adds a user as a member of this community
  # 
  # *Returns*
  #  - true if successful or user is already a member
  #  - false if unsuccessful
  def add_member(user_id)
    user = User.find_by_id(user_id.to_s)
    if user.nil? 
      return false
    end
    if nil == self.members.find_by_id(user.id) 
      self.members << user
      self.save
    end
    return true
  end


  # We cannot destroy a default community. A new default needs to
  # be set first
  def guard_default
    if self.is_default?
      self.errors[:base] << "We can't destroy the last default community"
      return false
    end
  end
end

