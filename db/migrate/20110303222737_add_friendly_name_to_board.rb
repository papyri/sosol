class AddFriendlyNameToBoard < ActiveRecord::Migration[4.2]
  def self.up
    add_column :boards, :friendly_name, :string
  end

  def self.down
    remove_column :boards, :friendly_name
  end
end
