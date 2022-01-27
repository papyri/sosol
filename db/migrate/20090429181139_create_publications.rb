# frozen_string_literal: true

class CreatePublications < ActiveRecord::Migration[4.2]
  def self.up
    create_table :publications do |t|
      t.string :title

      t.timestamps null: true
    end
  end

  def self.down
    drop_table :publications
  end
end
