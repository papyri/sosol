class Community < ActiveRecord::Base
  
  #worksA has_and_belongs_to_many :members, :class_name => "User", :foreign_key => "community_id", :join_table => "communities_members"
  #worksA has_and_belongs_to_many :admins, :class_name => "User",  :foreign_key => "community_id", :join_table => "communities_admins"
 
  has_and_belongs_to_many :members, :class_name => "User", :association_foreign_key => "user_id", :foreign_key => "community_id", :join_table => "communities_members"
  has_and_belongs_to_many :admins, :class_name => "User",  :association_foreign_key => "user_id", :foreign_key => "community_id", :join_table => "communities_admins"
  

  
end
