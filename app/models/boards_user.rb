class BoardsUser < ActiveRecord::Base
  belongs_to :user # foreign_key is user_id
  belongs_to :board # foreign_key is board_id
end