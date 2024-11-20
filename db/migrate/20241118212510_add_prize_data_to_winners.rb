class AddPrizeDataToWinners < ActiveRecord::Migration[7.0]
  def change
    add_column :winners, :prize_number, :string
    add_column :winners, :claimed, :boolean
  end
end
