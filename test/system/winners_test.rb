require "application_system_test_case"

class WinnersTest < ApplicationSystemTestCase
  setup do
    @winner = winners(:one)
  end

  test "visiting the index" do
    visit winners_url
    assert_selector "h1", text: "Winners"
  end

  test "should create winner" do
    visit winners_url
    click_on "New winner"

    click_on "Create Winner"

    assert_text "Winner was successfully created"
    click_on "Back"
  end

  test "should update Winner" do
    visit winner_url(@winner)
    click_on "Edit this winner", match: :first

    click_on "Update Winner"

    assert_text "Winner was successfully updated"
    click_on "Back"
  end

  test "should destroy Winner" do
    visit winner_url(@winner)
    click_on "Destroy this winner", match: :first

    assert_text "Winner was successfully destroyed"
  end
end
