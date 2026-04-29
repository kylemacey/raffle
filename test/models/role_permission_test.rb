require "test_helper"

class RolePermissionTest < ActiveSupport::TestCase
  test "prevents duplicate permission assignments for one role" do
    duplicate = RolePermission.new(role: roles(:cashier), permission: permissions(:pos_sell))

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:permission_id], "has already been taken"
  end
end
