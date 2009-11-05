class Comment < ActiveRecord::Base
  # belongs_to :article
  belongs_to :user
  belongs_to :publication
  belongs_to :identifier
end
