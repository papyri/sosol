class Vote < ActiveRecord::Base
  belongs_to :publication
  belongs_to :identifier
  belongs_to :user
end
