class AddIdentifierClassesToBoard < ActiveRecord::Migration
  def self.up
    add_column :boards, :identifier_classes, :text
  end

  def self.down
    remove_column :boards, :identifier_classes
  end
end
