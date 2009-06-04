class Vote < ActiveRecord::Base
  belongs_to :publication
  belongs_to :user
end
