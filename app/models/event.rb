class Event < ActiveRecord::Base
  belongs_to :user
  belongs_to :document
  
  validates_inclusion_of :type,
    :in => %w{ commit submit comment }
end
