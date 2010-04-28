class AddUrldisplayToDocos < ActiveRecord::Migration
  def self.up
    add_column :docos, :urldisplay, :string
  end

  def self.down
    remove_column :docos, :urldisplay
  end
end
