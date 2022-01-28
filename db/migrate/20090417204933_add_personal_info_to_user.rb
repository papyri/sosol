class AddPersonalInfoToUser < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :affiliation, :string
    add_column :users, :email, :string
  end

  def self.down
    remove_column :users, :first_name, :string
    remove_column :users, :last_name, :string
    remove_column :users, :affiliation, :string
    remove_column :users, :email, :string
  end
end
