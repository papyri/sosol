class Identifier < ActiveRecord::Base
  validates_inclusion_of :type,
                         :in => %w{ DDB }
end
