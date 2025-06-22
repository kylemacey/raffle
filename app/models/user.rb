class User < ApplicationRecord
  validates :pin, presence: true,
                  length: { is: 4, message: "must be exactly 4 digits" },
                  format: { with: /\A\d{4}\z/, message: "must contain only numbers" }
end
