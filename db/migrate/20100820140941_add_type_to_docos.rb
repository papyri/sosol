class AddTypeToDocos < ActiveRecord::Migration[4.2]
  def self.up
    add_column :docos, :docotype, :string, null: false, default: 'text'
    add_index :docos, :docotype
    add_index :docos, %i[id docotype]
    Doco.update_all ['docotype = ?', 'text'] if defined?(Doco)
  end

  def self.down
    remove_index :docos, %i[id docotype]
    remove_index :docos, :docotype
    remove_column :docos, :docotype
  end
end
