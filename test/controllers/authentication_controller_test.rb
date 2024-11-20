require "test_helper"

class AuthenticationControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get authentication_new_url
    assert_response :success
  end

  test "should get create" do
    get authentication_create_url
    assert_response :success
  end

  test "should get destroy" do
    get authentication_destroy_url
    assert_response :success
  end
end
