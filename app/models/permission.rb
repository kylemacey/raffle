class Permission < ApplicationRecord
  CAPABILITY_LABELS = {
    "events.view" => "View Events",
    "pos.sell" => "Create Orders",
    "customers.search" => "Search Supporters",
    "orders.view_own" => "View Own Orders",
    "card_readers.connect" => "Connect Card Reader",
    "orders.view_event" => "View Event Orders",
    "refunds.issue" => "Issue Refunds",
    "entries.manage" => "Manage Raffle Entries",
    "drawings.manage" => "Perform Raffle Drawings",
    "winners.manage" => "Record Winners",
    "reports.view_fundraising" => "View Event Financials",
    "subscriptions.view" => "View RocStar Subscription Data",
    "reports.view_pii" => "View Supporter Contact Data",
    "reports.download" => "Download Financial Reports",
    "events.manage" => "Manage Events",
    "orders.view_all" => "View All Orders",
    "card_readers.manage" => "Manage Card Reader Setup",
    "users.manage" => "Create Users",
    "roles.assign" => "Assign User Roles",
    "pos_products.manage" => "Manage Products",
    "roc_star_prices.manage" => "Manage RocStar Prices",
    "super_admin.assign" => "Assign SuperAdmin Role",
    "platform.impersonate" => "Impersonate Roles",
    "platform.break_glass" => "Platform Controls",
    "orders.delete" => "Delete Orders"
  }.freeze

  CAPABILITY_ORDER = CAPABILITY_LABELS.keys.freeze

  BADGE_CLASSES_BY_CATEGORY = {
    "events" => "text-bg-primary",
    "point_of_sale" => "text-bg-success",
    "orders" => "text-bg-info",
    "payments" => "text-bg-warning",
    "raffle" => "text-bg-secondary",
    "reporting" => "text-bg-light",
    "configuration" => "text-bg-dark border border-light",
    "admin" => "text-bg-danger",
    "platform" => "text-bg-danger"
  }.freeze

  has_many :role_permissions, dependent: :destroy
  has_many :roles, through: :role_permissions

  validates :key, presence: true, uniqueness: true
  validates :name, presence: true
  validates :category, presence: true

  scope :ordered, -> { order(:category, :name) }

  def capability_label
    CAPABILITY_LABELS.fetch(key, name)
  end

  def capability_weight
    CAPABILITY_ORDER.index(key) || CAPABILITY_ORDER.length
  end

  def capability_badge_class
    BADGE_CLASSES_BY_CATEGORY.fetch(category, "text-bg-secondary")
  end
end
