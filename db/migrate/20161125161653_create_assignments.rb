class CreateAssignments < ActiveRecord::Migration
  def up
    create_table :assignments do |t|
      t.integer   "user_id"
      t.datetime  "created_at",     :null => false
      t.datetime  "updated_at",     :null => false
      t.integer   "publication_id"
      t.integer   "board_id"
      t.integer   "vote_id"
    end
  end

  def down
    drop_table :assignments
  end
end
