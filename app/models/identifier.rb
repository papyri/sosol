class Identifier < ActiveRecord::Base
  validates_presence_of :name, :type
  
  belongs_to :publication
  
  # identifiers for a given publication
  # validates_uniqueness_of :name, :scope => "publication"
  validates_inclusion_of :type,
                         :in => %w{ DDBIdentifier }
end
