class CreateRocStarPrices < ActiveRecord::Migration[7.0]
  def change
    create_table :roc_star_prices do |t|
      t.string :name
      t.string :product_id
      t.integer :amount
      t.string :interval
      t.string :description

      t.timestamps
    end
  end
end
