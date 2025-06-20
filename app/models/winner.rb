class Winner < ApplicationRecord
  belongs_to :entry
  belongs_to :drawing
end
