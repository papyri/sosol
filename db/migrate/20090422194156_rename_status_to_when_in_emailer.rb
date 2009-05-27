class RenameStatusToWhenInEmailer < ActiveRecord::Migration
  def self.up
    	rename_column :emailers, :status, :when
  end

  def self.down
    	rename_column :emailers, :when, :status
  end
end
