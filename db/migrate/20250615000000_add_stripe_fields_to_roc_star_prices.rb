class AddStripeFieldsToRocStarPrices < ActiveRecord::Migration[7.0]
  def change
    add_column :roc_star_prices, :stripe_price_id, :string
    add_index :roc_star_prices, :stripe_price_id

    rename_column :roc_star_prices, :product_id, :stripe_product_id
  end
end