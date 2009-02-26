class CreateMetas < ActiveRecord::Migration
  def self.up
    create_table :metas do |t|
      t.string :notBeforeDate
      t.string :notAfterDate
      t.string :onDate
      t.string :publication
      t.string :language
      t.string :subject
      t.string :title
      t.string :provenance
      t.string :notes

      t.timestamps
    end
  end

  def self.down
    drop_table :metas
  end
end
