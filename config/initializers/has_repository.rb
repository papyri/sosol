module HasRepository
  def self.included(base)
    base.extend(ActMethods)
  end

  module ActMethods
    def has_repository
      unless included_modules.include? InstanceMethods
        extend ClassMethods
        include InstanceMethods
      end
    end
  end

  module ClassMethods
  end

  module InstanceMethods
    def repository
      @repository ||= Repository.new(self)
    end
  end
end

ActiveRecord::Base.include HasRepository
