class User < ActiveRecord::Base
  validates_uniqueness_of :name
  
  def repository
    @repository ||= Repository.new(self)
  end
end
