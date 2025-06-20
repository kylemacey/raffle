require "application_system_test_case"

class WinnersTest < ApplicationSystemTestCase
  setup do
    @winner = winners(:one)
    @admin = users(:admin)
    sign_in(@admin)
  end

  test "visiting the index" do
    visit event_drawing_winners_url(event_id: events(:one).id, drawing_id: drawings(:one).id)
    assert_selector "h1", text: "Winners"
  end

  test "creating a Winner" do
    visit new_event_drawing_winner_url(event_id: events(:one).id, drawing_id: drawings(:one).id)
    select entries(:one).name, from: "winner_entry_id"
    fill_in "Notes", with: @winner.notes
    check "Present" if @winner.present?
    fill_in "Prize", with: @winner.prize
    click_on "Create Winner"

    assert_text "Winner was successfully created"
  end

  test "updating a Winner" do
    visit edit_event_drawing_winner_url(event_id: events(:one).id, drawing_id: drawings(:one).id, id: @winner.id)
    select entries(:one).name, from: "winner_entry_id"
    fill_in "Notes", with: @winner.notes
    check "Present" if @winner.present?
    fill_in "Prize", with: @winner.prize
    click_on "Update Winner"

    assert_text "Winner was successfully updated"
  end

  test "destroying a Winner" do
    visit event_drawing_winners_url(event_id: events(:one).id, drawing_id: drawings(:one).id)
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Winner was successfully destroyed"
  end
end
