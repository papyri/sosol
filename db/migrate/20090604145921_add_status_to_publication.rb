class AddStatusToPublication < ActiveRecord::Migration
  def self.up
    add_column :publications, :status, :string
  end

  def self.down
    remove_column :publications, :status
  end
end
