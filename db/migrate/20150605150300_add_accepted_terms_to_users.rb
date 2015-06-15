class AddAcceptedTermsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :accepted_terms, :integer, :default => 0
  end

  def self.down
    remove_column :users, :accepted_terms
  end
end
