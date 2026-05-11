require "test_helper"

class SilentAuctionSettingTest < ActiveSupport::TestCase
  test "current returns singleton setting" do
    assert_equal silent_auction_settings(:default), SilentAuctionSetting.current
  end

  test "formats bid increment" do
    setting = SilentAuctionSetting.new(formatted_bid_increment: "30.50")

    assert_equal 3050, setting.bid_increment_cents
  end
end
