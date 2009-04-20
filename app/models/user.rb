class User < ActiveRecord::Base
  validates_uniqueness_of :name
  
  has_many :master_articles
  has_many :articles
  has_many :comments
  
  #has_many :boards
  #belongs_to :board
  has_and_belongs_to_many :boards
  
  belongs_to :emailers
end
