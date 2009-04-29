class Identifier < ActiveRecord::Base
  has_and_belongs_to_many :publications
  
  validates_inclusion_of :type,
                         :in => %w{ DDB }
end
