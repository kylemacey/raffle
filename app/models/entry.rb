class Entry < ApplicationRecord
  belongs_to :event
  has_many :winners, dependent: :destroy

  validates :name, presence: true
  validates :qty, presence: true, numericality: { greater_than: 0 }
end
