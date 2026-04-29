require "test_helper"

class PermissionTest < ActiveSupport::TestCase
  test "requires category" do
    permission = Permission.new(key: "reports.example", name: "Example")

    assert_not permission.valid?
    assert_includes permission.errors[:category], "can't be blank"
  end

  test "has many roles" do
    assert_includes permissions(:pos_sell).roles, roles(:cashier)
  end

  test "exposes human capability labels" do
    assert_equal "Create Orders", permissions(:pos_sell).capability_label
    assert_equal "Connect Card Reader", permissions(:card_readers_connect).capability_label
  end
end
