class Publication < ActiveRecord::Base
  validates_presence_of :title
  
  belongs_to :user
  has_and_belongs_to_many :identifiers
end
