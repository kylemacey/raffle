require "test_helper"

class FeedbackReportOverlayTest < ActionDispatch::IntegrationTest
  test "overlay appears for authenticated internal personas" do
    [
      users(:one),
      users(:two),
      users(:admin),
      user_with_role("Config Admin", "6677", :config_admin),
      user_with_role("Board Reporter", "6688", :board_reporter)
    ].each do |user|
      sign_in(user)
      get events_url

      assert_response :success
      assert_select "#feedbackReportModal"
      assert_select "button", text: /Feedback/
    end
  end

  test "feedback admin link appears for config admin" do
    user = user_with_role("Config Admin", "6677", :config_admin)
    sign_in(user)

    get events_url

    assert_response :success
    assert_select "a.dropdown-item[href='#{feedback_reports_path}']", text: "Feedback"
  end

  test "feedback admin link does not appear for event lead" do
    sign_in(users(:two))

    get events_url

    assert_response :success
    assert_select "a.dropdown-item[href='#{feedback_reports_path}']", count: 0
  end

  test "overlay does not appear for authenticated user without internal role" do
    user = User.create!(name: "No Role", pin: "9090")
    sign_in(user)

    get sign_in_path

    assert_response :success
    assert_select "#feedbackReportModal", count: 0
  end

  test "overlay does not appear on unauthenticated public surfaces" do
    get event_public_silent_auction_url(events(:one))

    assert_response :success
    assert_select "#feedbackReportModal", count: 0

    get new_session_roc_stars_url

    assert_response :success
    assert_select "#feedbackReportModal", count: 0
  end

  private

  def user_with_role(name, pin, role_key)
    User.find_or_create_by!(pin: pin) do |user|
      user.name = name
      user.admin = false
    end.tap do |user|
      user.roles = [roles(role_key)]
    end
  end
end
