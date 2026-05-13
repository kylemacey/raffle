require "test_helper"

class SilentAuctionSettingsControllerTest < ActionDispatch::IntegrationTest
  test "admin can update bid increment" do
    sign_in(users(:admin))

    patch silent_auction_setting_url, params: {
      silent_auction_setting: {
        formatted_bid_increment: "30.00"
      }
    }

    assert_redirected_to edit_silent_auction_setting_url
    assert_equal 3000, SilentAuctionSetting.current.reload.bid_increment_cents
  end

  test "event lead cannot update global setting" do
    sign_in(users(:two))

    patch silent_auction_setting_url, params: {
      silent_auction_setting: {
        formatted_bid_increment: "30.00"
      }
    }

    assert_redirected_to pos_main_url
  end
end
