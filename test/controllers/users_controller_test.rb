require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @admin = users(:admin)
    sign_in(@admin)
  end

  test "should get index" do
    get users_url
    assert_response :success
  end

  test "should get new" do
    get new_user_url
    assert_response :success
  end

  test "should create user" do
    assert_difference("User.count") do
      post users_url, params: { user: { admin: false, name: "New Cashier", pin: "8899", role_ids: [roles(:cashier).id] } }
    end

    user = User.last
    assert_redirected_to user_url(user)
    assert user.has_role?("cashier")
  end

  test "should show user" do
    get user_url(@user)
    assert_response :success
  end

  test "should get edit" do
    get edit_user_url(@user)
    assert_response :success
  end

  test "should update user" do
    patch user_url(@user), params: { user: { admin: @user.admin, name: @user.name, pin: @user.pin, role_ids: [roles(:event_lead).id] } }
    assert_redirected_to user_url(@user)
    assert @user.reload.has_role?("event_lead")
    assert_not @user.has_role?("cashier")
  end

  test "should destroy user" do
    user = User.create!(name: "Temporary User", pin: "4455", admin: false)

    assert_difference("User.count", -1) do
      delete user_url(user)
    end

    assert_redirected_to users_url
  end
end
