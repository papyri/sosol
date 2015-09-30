class AddIsDefaultToCommunities < ActiveRecord::Migration
  def change
    add_column :communities, :is_default, :boolean
  end
end
