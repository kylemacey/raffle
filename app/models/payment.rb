class Payment < ApplicationRecord
  belongs_to :entry, optional: true
  belongs_to :order, optional: true
end
