class CreateGlossaries < ActiveRecord::Migration
  def self.up
    create_table :glossaries do |t|
      t.string :item
      t.string :term
      t.string :en
      t.string :de
      t.string :fr
      t.string :sp
      t.string :la
      
      t.timestamps
    end
  end

  def self.down
    drop_table :glossaries
  end
end
