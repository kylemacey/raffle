class CreatePosProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :pos_products do |t|
      t.string :name
      t.integer :price
      t.string :stripe_product_id
      t.string :stripe_price_id
      t.string :product_type
      t.boolean :active
      t.references :event, null: false, foreign_key: true
      t.jsonb :configuration
      t.text :description

      t.timestamps
    end
  end
end
