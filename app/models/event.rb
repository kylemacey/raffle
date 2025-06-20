class Event < ApplicationRecord
  has_many :entries, dependent: :destroy
  has_many :drawings, dependent: :destroy
  belongs_to :user
end
