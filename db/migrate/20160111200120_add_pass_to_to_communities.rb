class AddPassToToCommunities < ActiveRecord::Migration
  def change
    add_column :communities, :pass_to, :string
  end
end
