class AddBranchToPublication < ActiveRecord::Migration
  def self.up
    add_column :publications, :branch, :string
  end

  def self.down
    remove_column :publications, :branch
  end
end
