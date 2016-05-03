class DropDocos < ActiveRecord::Migration
  def up
    drop_table :docos
  end

  def down
    create_table :docos do |t|
      t.decimal :line, :precision => 7, :scale =>2
      t.string :category
      t.string :description
      t.string :preview
      t.string :leiden
      t.string :xml
      t.string :url

      t.timestamps
    end
    add_column :docos, :urldisplay, :string
    add_column :docos, :note, :text
    add_column :docos, :docotype, :string, :null => false, :default => "text"
  	  add_index :docos, :docotype
  	  add_index :docos, [:id, :docotype]
      if defined?(Doco)
        Doco.update_all ["docotype = ?", "text"]
      end
  end
end
