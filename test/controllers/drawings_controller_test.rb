require "test_helper"

class DrawingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @drawing = drawings(:one)
    @event = events(:one)
    @admin = users(:admin)
    sign_in(@admin)
  end

  test "should get index" do
    get event_drawings_url(@event)
    assert_response :success
  end

  test "should get new" do
    get new_event_drawing_url(@event)
    assert_response :success
  end

  test "should create drawing" do
    assert_difference("Drawing.count") do
      post event_drawings_url(@event), params: { drawing: { event_id: @event.id, slug: @drawing.slug } }
    end

    assert_redirected_to event_drawing_winners_url(@event, Drawing.last)
  end

  test "should show drawing" do
    get event_drawing_url(@event, @drawing)
    assert_response :success
  end

  test "should destroy drawing" do
    assert_difference("Drawing.count", -1) do
      delete event_drawing_url(@event, @drawing)
    end

    assert_redirected_to event_drawings_url(@event)
  end
end
