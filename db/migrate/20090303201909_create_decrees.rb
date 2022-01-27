class CreateDecrees < ActiveRecord::Migration[4.2]
  def self.up
    create_table :decrees do |t|
      t.string :action
      t.decimal :trigger
      t.string :choices
      t.integer :board_id

      t.timestamps null: true
    end
  end

  def self.down
    drop_table :decrees
  end
end
