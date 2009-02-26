class User < ActiveRecord::Base
  validates_uniqueness_of :name
  
  has_many :master_articles
  has_many :articles
  has_many :comments
end
