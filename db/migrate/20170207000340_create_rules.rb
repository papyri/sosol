class CreateRules < ActiveRecord::Migration
  def change
    create_table :rules do |t|
      t.integer :expire_days
      t.decimal :floor,      :precision => 5, :scale => 2
      t.references :decree

      t.timestamps
    end
  end
end
