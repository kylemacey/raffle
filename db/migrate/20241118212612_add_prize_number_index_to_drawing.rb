class AddPrizeNumberIndexToDrawing < ActiveRecord::Migration[7.0]
  def change
    add_column :drawings, :prize_number_index, :string
  end
end
