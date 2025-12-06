require "test_helper"

class EntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @entry = entries(:one)
    @event = events(:one)
    @admin = users(:admin)
    sign_in(@admin)
  end

  test "should get index" do
    get event_entries_url(@event)
    assert_response :success
  end

  test "should get new" do
    get new_event_entry_url(@event)
    assert_response :success
  end

  test "should create entry" do
    assert_difference("Entry.count") do
      post event_entries_url(@event), params: { entry: { name: @entry.name, phone: @entry.phone, qty: @entry.qty } }
    end

    assert_redirected_to new_event_entry_url(@event)
  end

  test "should show entry" do
    get event_entry_url(@event, @entry)
    assert_response :success
  end

  test "should get edit" do
    get edit_event_entry_url(@event, @entry)
    assert_response :success
  end

  test "should update entry" do
    patch event_entry_url(@event, @entry), params: { entry: { name: @entry.name, phone: @entry.phone, qty: @entry.qty } }
    assert_redirected_to event_entries_url(@event)
  end

  test "should destroy entry" do
    assert_difference("Entry.count", -1) do
      delete event_entry_url(@event, @entry)
    end

    assert_redirected_to event_entries_url(@event)
  end
end
