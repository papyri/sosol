class AddLangPrefsToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :language_prefs, :string
  end

  def self.down
    remove_column :users, :language_prefs
  end
end
