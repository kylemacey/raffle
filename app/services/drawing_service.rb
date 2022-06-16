class DrawingService
  attr_reader :drawing, :event

  def initialize(drawing)
    @drawing = drawing
    @event = drawing.event
  end

  def perform_drawing
    drawing.save!
    to_draw = [drawing.qty.to_i, entries.length].min

    to_draw.times do
      winner = entries.shuffle!.pop
      drawing.winners.create(
        entry: winner
      )
    end

    return true
  end

  def entries
    @entries ||= event.entries.flat_map do |entry|
      entry.qty.times.map { entry }
    end
  end
end