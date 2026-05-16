class User < ApplicationRecord
  INTERNAL_OPERATOR_ROLE_KEYS = %w[
    cashier
    event_lead
    config_admin
    platform_admin
    board_reporter
  ].freeze

  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_many :permissions, -> { distinct }, through: :roles
  has_many :feedback_reports, dependent: :destroy

  validates :pin, presence: true,
                  length: { is: 4, message: "must be exactly 4 digits" },
                  format: { with: /\A\d{4}\z/, message: "must contain only numbers" }

  def role_keys
    roles.pluck(:key)
  end

  def permission_keys
    permissions.pluck(:key)
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

  def has_role?(key)
    roles.exists?(key: key.to_s)
  end

  def has_permission?(key)
    permissions.exists?(key: key.to_s)
  end

  def internal_operator?
    role_keys.any? { |key| INTERNAL_OPERATOR_ROLE_KEYS.include?(key) }
  end
end
