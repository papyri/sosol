class ChangeUserFirstNameLastNameToFullName < ActiveRecord::Migration
  def self.up
    add_column :users, :full_name, :string
    remove_column :users, :first_name
    remove_column :users, :last_name
  end

  def self.down
    remove_column :users, :full_name
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
  end
end
