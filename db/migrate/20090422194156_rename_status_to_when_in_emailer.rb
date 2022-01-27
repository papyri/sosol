# frozen_string_literal: true

class RenameStatusToWhenInEmailer < ActiveRecord::Migration[4.2]
  def self.up
    rename_column :emailers, :status, :when_to_send
  end

  def self.down
    rename_column :emailers, :when_to_send, :status
  end
end
