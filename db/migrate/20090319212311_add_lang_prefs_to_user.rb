class AddLangPrefsToUser < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :language_prefs, :string
  end

  def self.down
    remove_column :users, :language_prefs
  end
end
