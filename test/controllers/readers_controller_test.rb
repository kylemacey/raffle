require "test_helper"

class ReadersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in(users(:one))
  end

  test "should get list" do
    Stripe::Terminal::Reader.stub(:list, []) do
      Stripe::Terminal::Location.stub(:list, []) do
        get readers_list_url
        assert_response :success
      end
    end
  end

  test "should assign reader" do
    post readers_assign_url, params: { reader_id: 'tmr_123' }
    assert_redirected_to readers_list_path
  end
end
