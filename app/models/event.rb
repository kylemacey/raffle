class Event < ApplicationRecord
  has_many :entries, dependent: :destroy
  has_many :drawings, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :silent_auction_items, dependent: :destroy
end
