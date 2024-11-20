require "test_helper"

class ReadersControllerTest < ActionDispatch::IntegrationTest
  test "should get list" do
    get readers_list_url
    assert_response :success
  end

  test "should get assign" do
    get readers_assign_url
    assert_response :success
  end
end
