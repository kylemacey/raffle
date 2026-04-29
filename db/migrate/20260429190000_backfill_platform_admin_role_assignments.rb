class BackfillPlatformAdminRoleAssignments < ActiveRecord::Migration[7.0]
  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  class MigrationRole < ActiveRecord::Base
    self.table_name = "roles"
  end

  class MigrationUserRole < ActiveRecord::Base
    self.table_name = "user_roles"
  end

  def up
    platform_admin = MigrationRole.find_by(key: "platform_admin")
    return unless platform_admin

    MigrationUser.where(admin: true).find_each do |user|
      MigrationUserRole.find_or_create_by!(user_id: user.id, role_id: platform_admin.id)
    end
  end

  def down
    # Keep role assignments. They may have been intentionally changed after backfill.
  end
end
