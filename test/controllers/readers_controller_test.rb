require "test_helper"

class ReadersControllerTest < ActionDispatch::IntegrationTest
  test "should get list" do
    get readers_list_url
    assert_response :success
  end

  test "should get assign" do
    post readers_assign_url, params: { reader_id: 'tmr_123' }
    assert_response :redirect
  end
end
