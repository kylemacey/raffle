require "test_helper"

class WinnersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @winner = winners(:one)
    @drawing = drawings(:one)
    @event = events(:one)
    @admin = users(:admin)
    sign_in(@admin)
  end

  test "should get index" do
    get event_drawing_winners_url(@event, @drawing)
    assert_response :success
  end

  test "should get new" do
    get new_event_drawing_winner_url(@event, @drawing)
    assert_response :success
  end

  test "should show winner" do
    get event_drawing_winner_url(@event, @drawing, @winner)
    assert_response :success
  end

  test "should get edit" do
    get edit_event_drawing_winner_url(@event, @drawing, @winner)
    assert_response :success
  end

  test "should update winner" do
    patch event_drawing_winner_url(@event, @drawing, @winner), params: { winner: { entry_id: @winner.entry_id, prize: @winner.prize, present: @winner.present, notes: @winner.notes, drawing_id: @drawing.id } }
    assert_redirected_to event_drawing_winner_url(@event, @drawing, @winner)
  end

  test "should destroy winner" do
    assert_difference("Winner.count", -1) do
      delete event_drawing_winner_url(@event, @drawing, @winner)
    end

    assert_redirected_to event_drawing_winners_url(@event, @drawing)
  end
end
