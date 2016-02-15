class AddSubjectToEmailers < ActiveRecord::Migration
  def change
    add_column :emailers, :subject, :string
  end
end
