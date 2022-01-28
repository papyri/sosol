class DropDocos < ActiveRecord::Migration[4.2]
  def up
    drop_table :docos
  end

  def down
    create_table :docos do |t|
      t.decimal :line, precision: 7, scale: 2
      t.string :category
      t.string :description
      t.string :preview
      t.string :leiden
      t.string :xml
      t.string :url

      t.timestamps null: true
    end
    add_column :docos, :urldisplay, :string
    add_column :docos, :note, :text
    add_column :docos, :docotype, :string, null: false, default: 'text'
    add_index :docos, :docotype
    add_index :docos, %i[id docotype]
    Doco.update_all ['docotype = ?', 'text'] if defined?(Doco)
  end
end
