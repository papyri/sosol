class Translation < ActiveRecord::Base
  belongs_to :article
  has_many :translations
end
