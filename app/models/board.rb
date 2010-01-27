#Board represents an editorial review board.
class Board < ActiveRecord::Base
  has_many :decrees, :dependent => :destroy
  has_many :emailers, :dependent => :destroy
  
  has_many :votes
  
  has_and_belongs_to_many :users
  belongs_to :finalizer_user, :class_name => 'User'
  
  has_many :publications, :as => :owner, :dependent => :destroy
  has_many :events, :as => :owner
  
  # :identifier_classes is an array of identifier classes this board has
  # commit control over. This isn't done relationally because it's not a
  # relation to instances of identifiers but rather to identifier classes
  # themselves.
  serialize :identifier_classes
  
  validates_uniqueness_of :title, :case_sensitive => false
  validates_presence_of :title
  
  has_repository
  
  # workaround repository need for owner name for now
  def name
    return title
  end
  
  def after_create
    repository.create
  end
  
  def before_destroy
    repository.destroy
  end
  
  def result_actions
    #return array of possible actions that can be implemented
    retval = []
    identifier_classes.each do |ic|
      im = ic.constantize.instance_methods
      match_expression = /(result_action_)/
      im.each do |method_name|
        if method_name =~ /(result_action_)/
          retval << method_name.sub(/(result_action_)/, "")
        end
      end
    end
    retval
    
  end
  
  def result_actions_hash  
    ra = result_actions    
    ret_hash = {}
    
    #create hash
    ra.each do |v|
      ret_hash[v.sub(/_/, " ").capitalize] = v
    end
    ret_hash
  end

  def controls_identifier?(identifier)
   self.identifier_classes.include?(identifier.class.to_s)  
  end



  #Tallies the votes and returns the resulting decree action or returns an empty string if no decree has been triggered.
  def tally_votes(votes)
    # NOTE: assumes board controls one identifier type, and user hasn't made
    # rules where multiple decrees can be true at once
    
    self.decrees.each do |decree|
      if decree.perform_action?(votes)
        return decree.action
      end
    end
    
    return ""
  end #tally_votes
end
