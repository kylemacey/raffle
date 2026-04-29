require "test_helper"

class UserRoleTest < ActiveSupport::TestCase
  test "prevents duplicate role assignments for one user" do
    duplicate = UserRole.new(user: users(:one), role: roles(:cashier))

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:role_id], "has already been taken"
  end
end
