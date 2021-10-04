class ChangeEmailerIdToBeIntegerInEmailersUsers < ActiveRecord::Migration[5.2]
  def up
    change_column :emailers_users, :emailer_id, "integer USING NULLIF(emailer_id, '')::int"
  end

  def down
    change_column :emailers_users, :emailer_id, "string USING NULLIF(emailer_id, '')::string"
  end
end
