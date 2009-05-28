class Board < ActiveRecord::Base
  has_many :decrees
  has_many :emailers

  has_and_belongs_to_many :users
  has_many :publications, :as => :owner
  has_many :events, :as => :owner
  
  # :identifier_classes is an array of identifier classes this board has
  # commit control over. This isn't done relationally because it's not a
  # relation to instances of identifiers but rather to identifier classes
  # themselves.
  serialize :identifier_classes

  def tally_votes(votes)
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
      if decree.trigger < 1
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
      else 
        #min vote count
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
