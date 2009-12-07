class AddDefaultsToStatus < ActiveRecord::Migration
  def self.up
    change_column :publications, :status, :string, :default => "editing"
  end

  def self.down
    change_column :publications, :status, :string
  end
end
