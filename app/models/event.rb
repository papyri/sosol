class Event < ActiveRecord::Base
  # belongs_to :user
  # belongs_to :article
  
  validates_inclusion_of :category,
    :in => %w{ commit submit comment }
end
