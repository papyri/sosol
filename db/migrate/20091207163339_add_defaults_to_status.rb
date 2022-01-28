class AddDefaultsToStatus < ActiveRecord::Migration[4.2]
  def self.up
    change_column :publications, :status, :string, default: 'editing'
  end

  def self.down
    change_column :publications, :status, :string
  end
end
