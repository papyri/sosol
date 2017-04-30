class AddNextBoardToPublications < ActiveRecord::Migration
  def change
    add_column :publications, :next_board, :integer
  end
end
