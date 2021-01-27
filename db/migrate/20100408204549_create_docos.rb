class CreateDocos < ActiveRecord::Migration
  def self.up
    #create_table :docos, :options => 'default charset=utf8' do |t| - for creating in mysql as standalone
    create_table :docos do |t|
      t.decimal :line, :precision => 7, :scale =>2
      t.string :category
      t.string :description
      t.string :preview
      t.string :leiden
      t.string :xml
      t.string :url

      t.timestamps null: true
    end
  end

  def self.down
    drop_table :docos
  end
end
