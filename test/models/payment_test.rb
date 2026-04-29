require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  test "can belong to an entry for legacy raffle payments" do
    assert_equal entries(:one), payments(:one).entry
  end
end
