class SeedFeedbackReportPermissions < ActiveRecord::Migration[7.0]
  class MigrationRole < ActiveRecord::Base
    self.table_name = "roles"
  end

  class MigrationPermission < ActiveRecord::Base
    self.table_name = "permissions"
  end

  class MigrationRolePermission < ActiveRecord::Base
    self.table_name = "role_permissions"
  end

  PERMISSIONS = [
    ["feedback_reports.view", "View feedback reports", "admin", "Review internal operator feedback and bug reports."]
  ].freeze

  ROLE_PERMISSIONS = {
    "platform_admin" => ["feedback_reports.view"],
    "config_admin" => ["feedback_reports.view"]
  }.freeze

  def up
    PERMISSIONS.each do |key, name, category, description|
      MigrationPermission.find_or_create_by!(key: key) do |permission|
        permission.name = name
        permission.category = category
        permission.description = description
      end
    end

    ROLE_PERMISSIONS.each do |role_key, permission_keys|
      role = MigrationRole.find_by(key: role_key)
      next unless role

      permission_keys.each do |permission_key|
        permission = MigrationPermission.find_by!(key: permission_key)
        MigrationRolePermission.find_or_create_by!(
          role_id: role.id,
          permission_id: permission.id
        )
      end
    end
  end

  def down
    permission_keys = PERMISSIONS.map(&:first)
    MigrationRolePermission.where(permission_id: MigrationPermission.where(key: permission_keys).select(:id)).delete_all
    MigrationPermission.where(key: permission_keys).delete_all
  end
end
