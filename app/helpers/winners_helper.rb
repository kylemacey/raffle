module WinnersHelper
  def next_winner(drawing, winner)
    drawing.winners.where(["id > ?", winner.id]).order(id: :asc).limit(1).first
  end

  def prev_winner(drawing, winner)
    drawing.winners.where(["id < ?", winner.id]).order(id: :desc).limit(1).first
  end
end
