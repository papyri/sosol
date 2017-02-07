class CreateRules < ActiveRecord::Migration
  def change
    create_table :rules do |t|
      t.int :expire_days
      t.int :floor
      t.references :decree

      t.timestamps
    end
  end
end
