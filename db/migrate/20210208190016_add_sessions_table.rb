# frozen_string_literal: true

class AddSessionsTable < ActiveRecord::Migration[4.2]
  def change
    create_table :sessions do |t|
      t.string :session_id, null: false
      t.text :data
      t.timestamps null: true
    end

    add_index :sessions, :session_id, unique: true
    add_index :sessions, :updated_at
  end
end
