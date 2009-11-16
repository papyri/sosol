class AddTallyMethodToDecree < ActiveRecord::Migration
  def self.up
    add_column :decrees, :tally_method, :string
  end

  def self.down
    remove_column :decrees, :tally_method
  end
end
