# frozen_string_literal: true

class AddTallyMethodToDecree < ActiveRecord::Migration[4.2]
  def self.up
    add_column :decrees, :tally_method, :string
  end

  def self.down
    remove_column :decrees, :tally_method
  end
end
