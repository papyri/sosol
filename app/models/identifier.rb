class Identifier < ActiveRecord::Base
  validates_presence_of :name, :type
  
  has_and_belongs_to_many :publications
  
  # identifiers of the same type must be unique
  validates_uniqueness_of :name, :scope => "type"
  validates_inclusion_of :type,
                         :in => %w{ DDB }
end
