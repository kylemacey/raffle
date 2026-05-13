class SeedSilentAuctionPermissions < ActiveRecord::Migration[7.0]
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
    ["silent_auction.manage", "Manage silent auction", "silent_auction", "Create items, manage bidding state, and close auction items."],
    ["invoice_settings.manage", "Manage invoice settings", "configuration", "Manage shared invoice settings and Stripe invoice-template handoff."]
  ].freeze

  ROLE_PERMISSIONS = {
    "platform_admin" => ["silent_auction.manage", "invoice_settings.manage"],
    "config_admin" => ["silent_auction.manage", "invoice_settings.manage"],
    "event_lead" => ["silent_auction.manage"]
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
