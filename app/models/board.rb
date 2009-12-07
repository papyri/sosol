#Board represents an editorial review board.
class Board < ActiveRecord::Base
  has_many :decrees
  has_many :emailers

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
      eval_statement = ic + ".instance_methods"
      im = eval(eval_statement)
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
  #if we want a board to control more than one identifier type we must change it here
    #work in progress
    #how to determine order -- just assume user hasn't made rules where multiple decress can be true at once?
    #errMsg = " "    
    self.decrees.each do |decree|

      #pull choices out
      decree_choices = decree.choices.split(' ')       
      #count votes
      decree_vote_count = 0
      votes.each do |vote|        
        #see if vote is in choices
        index = decree_choices.index(vote.choice) #double check that this doesn't return true for "no" in "known"
        if  index != nil
          decree_vote_count = decree_vote_count + 1            
        end
      end 

      #see if we are using percent or min voting counting
      if decree.tally_method == "percentage"
        #percentage
        if decree_vote_count > 0 && self.users.length.to_f > 0
          percent =  decree_vote_count.to_f / self.users.length.to_f

          if percent >= decree.trigger
            #check if the action has already been done
            #do the action? or return the action?
            #   
            #errMsg += percent.to_s  
            return decree.action
          end
        end
      elsif decree.tally_method == "count"
        #min absolute vote count
        if decree_vote_count >= decree.trigger
          #check if the action has already been done
          #do the action? or return the action?
          #
          #errMsg += " " + decree_vote_count + " " + vote.choice + " " 
          return decree.action
        end

      end

    end    #decree 

    #raise errMsg
    return ""

  end #tally_votes
end
