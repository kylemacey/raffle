class Drawing < ApplicationRecord
  attr_accessor :qty, :can_win_again

  belongs_to :event
  has_many :winners
end
