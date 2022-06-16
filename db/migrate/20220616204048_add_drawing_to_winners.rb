class AddDrawingToWinners < ActiveRecord::Migration[7.0]
  def change
    add_reference :winners, :drawing, null: false, foreign_key: true
  end
end
