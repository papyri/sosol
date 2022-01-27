# frozen_string_literal: true

class ChangeCommentToText < ActiveRecord::Migration[4.2]
  def self.up
    change_column :comments, :comment, :text, limit: nil
  end

  def self.down
    change_column :comments, :comment, :string, limit: 255
  end
end
