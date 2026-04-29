class AddPriorityToPosProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :pos_products, :priority, :integer
  end
end
