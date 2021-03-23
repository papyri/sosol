class AddUrldisplayToDocos < ActiveRecord::Migration[4.2]
  def self.up
    add_column :docos, :urldisplay, :string
  end

  def self.down
    remove_column :docos, :urldisplay
  end
end
