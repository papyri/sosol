class Event < ActiveRecord::Base
  belongs_to :user
  
  validates_inclusion_of :type,
    :in => %w{ commit submit comment }
end
