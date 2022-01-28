class UserIdentifier < ApplicationRecord
  belongs_to :user
  validates :identifier, presence: true
  validates :identifier, uniqueness: { case_sensitive: false }
end
