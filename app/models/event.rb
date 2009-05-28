class Event < ActiveRecord::Base
  belongs_to :owner, :polymorphic => true
  belongs_to :target, :polymorphic => true
  
  validates_inclusion_of :category,
    :in => %w{ commit submit comment created }
end
