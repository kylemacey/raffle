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
      post users_url, params: { user: { name: "New Cashier", pin: "8899", role_ids: [roles(:cashier).id] } }
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
    patch user_url(@user), params: { user: { name: @user.name, pin: @user.pin, role_ids: [roles(:event_lead).id] } }
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

  test "config admin cannot assign platform admin role" do
    config_admin = User.create!(name: "Config Admin", pin: "6677")
    config_admin.roles << roles(:config_admin)
    sign_in(config_admin)

    assert_no_difference("User.count") do
      post users_url, params: { user: { name: "Break Glass", pin: "7766", role_ids: [roles(:platform_admin).id] } }
    end

    assert_response :forbidden
  end

  test "config admin receives json errors when creating platform admin role assignment" do
    config_admin = User.create!(name: "Config Admin", pin: "6677")
    config_admin.roles << roles(:config_admin)
    sign_in(config_admin)

    assert_no_difference("User.count") do
      post users_url(format: :json), params: { user: { name: "Break Glass", pin: "7766", role_ids: [roles(:platform_admin).id] } }
    end

    assert_response :forbidden
    assert_includes JSON.parse(response.body)["base"], "You are not authorized to assign SuperAdmin."
  end

  test "config admin receives json errors when updating platform admin role assignment" do
    config_admin = User.create!(name: "Config Admin", pin: "6677")
    config_admin.roles << roles(:config_admin)
    sign_in(config_admin)

    patch user_url(@user, format: :json), params: { user: { name: @user.name, pin: @user.pin, role_ids: [roles(:platform_admin).id] } }

    assert_response :forbidden
    assert_includes JSON.parse(response.body)["base"], "You are not authorized to assign SuperAdmin."
  end

  test "platform admin can assign platform admin role" do
    assert_difference("User.count") do
      post users_url, params: { user: { name: "Break Glass", pin: "7766", role_ids: [roles(:platform_admin).id] } }
    end

    assert User.last.has_role?("platform_admin")
  end
end
