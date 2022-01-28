class AddBoardUsersTable < ActiveRecord::Migration[4.2]
  def self.up
    create_table :boards_users, id: false do |t|
      t.string :board_id
      t.integer :user_id

      t.timestamps null: true
    end

    add_index :boards_users, %i[board_id user_id], unique: true
  end

  def self.down
    drop_table :boards_users
  end
end
