require "test_helper"

class AuthenticationControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get sign_in_path
    assert_response :success
  end

  test "should get create" do
    post authentication_create_path, params: { pin: users(:one).pin }
    assert_response :redirect
  end

  test "should get destroy" do
    delete authentication_path
    assert_response :redirect
  end
end
