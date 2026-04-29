require "test_helper"

class RoleTest < ActiveSupport::TestCase
  test "requires a unique key" do
    duplicate = Role.new(key: roles(:cashier).key, name: "Duplicate")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:key], "has already been taken"
  end

  test "has many permissions" do
    assert_includes roles(:cashier).permissions, permissions(:pos_sell)
  end

  test "orders roles from least to most powerful" do
    assert_equal(
      %w[cashier event_lead board_reporter config_admin platform_admin],
      Role.ordered.map(&:key)
    )
  end

  test "renders expanded capability badges" do
    labels = roles(:event_lead).capability_badges.map { |badge| badge[:label] }

    assert_includes labels, "Create Orders"
    assert_includes labels, "Connect Card Reader"
    assert_includes labels, "Issue Refunds"
    assert_includes labels, "Perform Raffle Drawings"
  end
end
