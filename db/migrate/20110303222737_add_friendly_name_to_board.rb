class AddFriendlyNameToBoard < ActiveRecord::Migration
  def self.up
    add_column :boards, :friendly_name, :string
  end

  def self.down
    remove_column :boards, :friendly_name
  end
end
