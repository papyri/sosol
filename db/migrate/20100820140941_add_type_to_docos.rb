class AddTypeToDocos < ActiveRecord::Migration[4.2]
  def self.up
    add_column :docos, :docotype, :string, :null => false, :default => "text"
  	  add_index :docos, :docotype
  	  add_index :docos, [:id, :docotype]
  	  if defined?(Doco)
        Doco.update_all ["docotype = ?", "text"]
      end
  end

  def self.down
    remove_index :docos, [:id, :docotype]
    remove_index :docos, :docotype
    remove_column :docos, :docotype
  end
end
