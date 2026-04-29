class CreateRbacScaffold < ActiveRecord::Migration[7.0]
  class MigrationUser < ActiveRecord::Base
    self.table_name = "users"
  end

  class MigrationRole < ActiveRecord::Base
    self.table_name = "roles"
    has_many :user_roles, class_name: "CreateRbacScaffold::MigrationUserRole", foreign_key: :role_id
    has_many :role_permissions, class_name: "CreateRbacScaffold::MigrationRolePermission", foreign_key: :role_id
  end

  class MigrationPermission < ActiveRecord::Base
    self.table_name = "permissions"
  end

  class MigrationUserRole < ActiveRecord::Base
    self.table_name = "user_roles"
  end

  class MigrationRolePermission < ActiveRecord::Base
    self.table_name = "role_permissions"
  end

  PERMISSIONS = [
    ["events.view", "View events", "events", "View event lists, dashboards, and operational context."],
    ["events.manage", "Manage events", "events", "Create and edit event records."],
    ["entries.manage", "Manage entries", "raffle", "Create, edit, import, and delete raffle entries."],
    ["drawings.manage", "Manage drawings", "raffle", "Create drawings and inspect drawing output."],
    ["winners.manage", "Manage winners", "raffle", "Find winners and update claim status."],
    ["pos.sell", "Sell through POS", "point_of_sale", "Use the point-of-sale workflow to create orders."],
    ["customers.search", "Search customers", "point_of_sale", "Search customer records during checkout."],
    ["orders.view_own", "View own orders", "orders", "View orders created by the current user."],
    ["orders.view_event", "View event orders", "orders", "View orders for an active event."],
    ["orders.view_all", "View all orders", "orders", "View all orders across events."],
    ["orders.delete", "Delete orders", "orders", "Delete order records when recovery requires it."],
    ["refunds.issue", "Issue refunds", "payments", "Issue refunds for paid orders."],
    ["card_readers.connect", "Connect card reader", "payments", "Connect or select a Stripe Terminal reader during checkout."],
    ["card_readers.manage", "Manage card readers", "payments", "Assign Stripe Terminal readers and manage reader setup."],
    ["users.manage", "Manage users", "admin", "Create and edit users and PINs."],
    ["roles.assign", "Assign roles", "admin", "Assign RBAC roles to users."],
    ["super_admin.assign", "Assign SuperAdmin role", "admin", "Assign the highest-power platform role."],
    ["pos_products.manage", "Manage POS products", "configuration", "Create, edit, activate, and reorder POS products."],
    ["roc_star_prices.manage", "Manage RocStar prices", "configuration", "Manage recurring subscription price records."],
    ["reports.view_fundraising", "View fundraising reports", "reporting", "View fundraising totals, MRR, and payment-method breakdowns."],
    ["reports.view_pii", "View report PII", "reporting", "View supporter contact details in reporting surfaces."],
    ["reports.download", "Download financial reports", "reporting", "Download financial report exports."],
    ["subscriptions.view", "View subscriptions", "reporting", "View RocStar supporter/subscription context."],
    ["platform.impersonate", "Impersonate roles", "platform", "Use role impersonation for testing and support."],
    ["platform.break_glass", "Use break-glass controls", "platform", "Use platform-level rescue controls during live incidents."]
  ].freeze

  ROLES = [
    [
      "platform_admin",
      "SuperAdmin",
      "Break-glass operator for live incidents and developer/testing workflows.",
      PERMISSIONS.map(&:first)
    ],
    [
      "config_admin",
      "Admin",
      "Trusted technical board member responsible for setup, reliability, products, users, and Stripe-linked configuration.",
      [
        "events.view",
        "pos.sell",
        "customers.search",
        "orders.view_own",
        "card_readers.connect",
        "orders.view_event",
        "refunds.issue",
        "entries.manage",
        "drawings.manage",
        "winners.manage",
        "reports.view_fundraising",
        "subscriptions.view",
        "reports.view_pii",
        "reports.download",
        "events.manage",
        "orders.view_all",
        "card_readers.manage",
        "users.manage",
        "roles.assign",
        "pos_products.manage",
        "roc_star_prices.manage"
      ]
    ],
    [
      "event_lead",
      "Event Lead",
      "Board member responsible for smooth event operations, raffle integrity, and guest experience.",
      [
        "events.view",
        "pos.sell",
        "customers.search",
        "orders.view_own",
        "card_readers.connect",
        "orders.view_event",
        "refunds.issue",
        "entries.manage",
        "drawings.manage",
        "winners.manage",
        "reports.view_fundraising"
      ]
    ],
    [
      "cashier",
      "Cashier",
      "Event-day volunteer focused on fast, low-stress POS checkout.",
      [
        "events.view",
        "pos.sell",
        "customers.search",
        "orders.view_own",
        "card_readers.connect"
      ]
    ],
    [
      "board_reporter",
      "Financial Analyst",
      "Board leader who needs fundraising health, RocStar context, and secure supporter visibility.",
      [
        "events.view",
        "reports.view_fundraising",
        "subscriptions.view",
        "reports.view_pii",
        "reports.download"
      ]
    ]
  ].freeze

  def up
    create_table :roles do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.text :description
      t.boolean :system, null: false, default: true

      t.timestamps
    end
    add_index :roles, :key, unique: true

    create_table :permissions do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.string :category, null: false
      t.text :description

      t.timestamps
    end
    add_index :permissions, :key, unique: true
    add_index :permissions, :category

    create_table :user_roles do |t|
      t.references :user, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true

      t.timestamps
    end
    add_index :user_roles, [:user_id, :role_id], unique: true

    create_table :role_permissions do |t|
      t.references :role, null: false, foreign_key: true
      t.references :permission, null: false, foreign_key: true

      t.timestamps
    end
    add_index :role_permissions, [:role_id, :permission_id], unique: true

    seed_permissions
    seed_roles
    backfill_platform_admins
  end

  def down
    drop_table :role_permissions
    drop_table :user_roles
    drop_table :permissions
    drop_table :roles
  end

  private

  def seed_permissions
    PERMISSIONS.each do |key, name, category, description|
      MigrationPermission.create!(
        key: key,
        name: name,
        category: category,
        description: description
      )
    end
  end

  def seed_roles
    ROLES.each do |key, name, description, permission_keys|
      role = MigrationRole.create!(
        key: key,
        name: name,
        description: description,
        system: true
      )

      permission_keys.each do |permission_key|
        permission = MigrationPermission.find_by!(key: permission_key)
        MigrationRolePermission.create!(role_id: role.id, permission_id: permission.id)
      end
    end
  end

  def backfill_platform_admins
    platform_admin = MigrationRole.find_by!(key: "platform_admin")

    MigrationUser.where(admin: true).find_each do |user|
      MigrationUserRole.find_or_create_by!(user_id: user.id, role_id: platform_admin.id)
    end
  end
end
