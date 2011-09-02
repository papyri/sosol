class Community < ActiveRecord::Base
  
  #worksA has_and_belongs_to_many :members, :class_name => "User", :foreign_key => "community_id", :join_table => "communities_members"
  #worksA has_and_belongs_to_many :admins, :class_name => "User",  :foreign_key => "community_id", :join_table => "communities_admins"
 
  has_and_belongs_to_many :members, :class_name => "User", :association_foreign_key => "user_id", :foreign_key => "community_id", :join_table => "communities_members"
  has_and_belongs_to_many :admins, :class_name => "User",  :association_foreign_key => "user_id", :foreign_key => "community_id", :join_table => "communities_admins"
  
  
  has_many :boards
  has_many :publications
  
  
  

  def end_user
    return User.find_by_id(self.end_user_id)
  end
  
  
  #check to see whether or not to allow members to submit to the community
  def is_submittable?
    
    #if there is nowhere for the final publication to go, don't let them submit
    return end_user.nil?
  end
end
