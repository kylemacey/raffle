class AddCustomerPhoneToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :customer_phone, :string unless column_exists?(:orders, :customer_phone)
  end
end
