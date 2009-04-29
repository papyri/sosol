class CreateIdentifiersPublications < ActiveRecord::Migration
  def self.up
    create_table :identifiers_publications do |t|
      t.integer :identifier_id
      t.integer :publication_id
    end
  end

  def self.down
    drop_table :identifiers_publications
  end
end
