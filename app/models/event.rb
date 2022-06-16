class Event < ApplicationRecord
  has_many :entries
  has_many :drawings
end
