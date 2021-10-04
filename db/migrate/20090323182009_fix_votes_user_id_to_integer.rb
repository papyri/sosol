class FixVotesUserIdToInteger < ActiveRecord::Migration[4.2]
  def self.up
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      change_column :votes, :user_id, "integer USING NULLIF(user_id, '')::int"
    else
      change_column :votes, :user_id, :integer
    end
  end

  def self.down
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      change_column :votes, :user_id, "string USING NULLIF(user_id, '')::string"
    else
      change_column :votes, :user_id, :string
    end
  end
end
