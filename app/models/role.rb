class Role < ApplicationRecord
  POWER_LEVELS = {
    "cashier" => 10,
    "event_lead" => 20,
    "board_reporter" => 30,
    "config_admin" => 40,
    "platform_admin" => 50
  }.freeze

  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles
  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions

  validates :key, presence: true, uniqueness: true
  validates :name, presence: true

  scope :ordered, lambda {
    order(Arel.sql(<<~SQL.squish), :name)
      CASE roles.key
      WHEN 'cashier' THEN 10
      WHEN 'event_lead' THEN 20
      WHEN 'board_reporter' THEN 30
      WHEN 'config_admin' THEN 40
      WHEN 'platform_admin' THEN 50
      ELSE 999
      END
    SQL
  }

  def power_level
    POWER_LEVELS.fetch(key, 999)
  end

  def capability_badges
    permissions.sort_by(&:capability_weight).map do |permission|
      {
        key: permission.key,
        label: permission.capability_label,
        css_class: permission.capability_badge_class
      }
    end
  end
end
