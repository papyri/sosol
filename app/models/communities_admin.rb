# frozen_string_literal: true

class CommunitiesAdmin < ApplicationRecord
  belongs_to :community # foreign_key is community_id
  belongs_to :user # foreign_key is user_id
end
