class ChangeEmailerIdToBeIntegerInEmailersUsers < ActiveRecord::Migration[5.2]
  def up
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      change_column :emailers_users, :emailer_id, "integer USING NULLIF(emailer_id, '')::int"
    else
      change_column :emailers_users, :emailer_id, :integer
    end
  end

  def down
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      change_column :emailers_users, :emailer_id, "string USING NULLIF(emailer_id, '')::string"
    else
      change_column :emailers_users, :emailer_id, :string
    end
  end
end
