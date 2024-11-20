class DrawingService
  attr_reader :drawing, :event

  def initialize(drawing)
    @drawing = drawing
    @event = drawing.event
    # I was going to support more prizes being drawn afterward, but I'm not
    # really sure how needed this is. Just draw more than you think you need
    #
    # @next_prize_number = @drawing.prize_number_index || next_prize_number
  end

  def perform_drawing
    drawing.save!
    to_draw = [drawing.qty.to_i, entries.length].min

    Winner.transaction do
      to_draw.times do
        winner = entries.shuffle!.pop
        drawing.winners.create(
          entry: winner,
          prize_number: next_prize_number
        )
      end
      save_next_prize_number_index
    end

    return true
  end

  private

  def entries
    @entries ||= event.entries.flat_map do |entry|
      entry.qty.times.map { entry }
    end
  end

  def next_prize_number
    a, b = (@next_prize_number || INITIAL_PRIZE_NUMBER).split("-").map(&:to_i)
    b += 1
    if b > 50
      a += 1
      b = 0
    end
    @next_prize_number = self.class.format_prize_number(a, b)
  rescue
    binding.pry
  end

  def self.format_prize_number(a, b)
    [a,b].map do |i|
      i.to_s.rjust(2, "0")
    end.join("-")
  end

  def save_next_prize_number_index
    drawing.prize_number_index = @next_prize_number
    drawing.save!
  end

  INITIAL_PRIZE_NUMBER = format_prize_number(0, 0)
end