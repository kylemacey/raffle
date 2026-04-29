require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  test "cashier sees only own orders" do
    own_order = Order.create!(
      customer_name: "Cashier Customer",
      customer_email: "cashier@example.com",
      total_amount: 100,
      event: events(:one),
      user: users(:one),
      payment_method_type: "cash"
    )
    own_order.create_payment!(payment_method_type: "cash", amount: 100)

    sign_in(users(:one))

    get orders_url(show_pending: true)

    assert_response :success
    assert_includes response.body, "Order ID"
    assert_includes response.body, own_order.customer_name
    assert_not_includes response.body, orders(:one).customer_name
  end

  test "event lead sees orders for selected event" do
    sign_in(users(:two))
    post pos_create_path, params: { event_id: events(:one).id }

    get orders_url(show_pending: true)

    assert_response :success
    assert_includes response.body, orders(:one).customer_name
    assert_not_includes response.body, orders(:two).customer_name
  end

  test "cashier cannot view another user's order" do
    sign_in(users(:one))

    get order_url(orders(:one))

    assert_redirected_to orders_url
  end

  test "cashier cannot delete orders" do
    sign_in(users(:one))

    assert_no_difference("Order.count") do
      delete order_url(orders(:one))
    end

    assert_redirected_to pos_main_path
  end

  test "platform admin can delete orders" do
    sign_in(users(:admin))

    assert_difference("Order.count", -1) do
      delete order_url(orders(:one))
    end

    assert_redirected_to orders_url
  end
end
