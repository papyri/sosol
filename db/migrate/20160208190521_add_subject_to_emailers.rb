# frozen_string_literal: true

class AddSubjectToEmailers < ActiveRecord::Migration[4.2]
  def change
    add_column :emailers, :subject, :string
  end
end
