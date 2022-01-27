# frozen_string_literal: true

class UserIdentifier < ApplicationRecord
  belongs_to :user
  validates_presence_of :identifier
  validates_uniqueness_of :identifier, case_sensitive: false
end
