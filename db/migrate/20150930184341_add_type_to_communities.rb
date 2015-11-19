class AddTypeToCommunities < ActiveRecord::Migration
  def change
    add_column :communities, :type, :string, :null => false, :default => "EndUserCommunity"
  end
end
