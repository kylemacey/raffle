require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "pin must be exactly four digits" do
    user = User.new(name: "Volunteer", pin: "abcd")

    assert_not user.valid?
    assert_includes user.errors[:pin], "must contain only numbers"
  end

  test "reports role keys" do
    assert_equal ["cashier"], users(:one).role_keys
  end

  test "checks role assignment by key" do
    assert users(:one).has_role?("cashier")
    assert_not users(:one).has_role?("platform_admin")
  end

  test "checks effective permissions through roles" do
    assert users(:one).has_permission?("pos.sell")
    assert_not users(:one).has_permission?("users.manage")
  end

  test "renders effective capabilities through roles" do
    labels = users(:one).capability_badges.map { |badge| badge[:label] }

    assert_includes labels, "Create Orders"
    assert_includes labels, "Connect Card Reader"
  end
end
