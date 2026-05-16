require "test_helper"

class FeedbackReportTest < ActiveSupport::TestCase
  setup do
    @report = FeedbackReport.new(
      user: users(:one),
      user_name: users(:one).name,
      role_keys: ["cashier"],
      report_type: "bug",
      message: "Checkout button did not respond.",
      current_path: "/pos/main",
      browser_metadata: { "viewport_width" => "1200" }
    )
  end

  test "is valid with required durable payload" do
    assert @report.valid?
  end

  test "requires a supported report type" do
    @report.report_type = "incident"

    assert_not @report.valid?
    assert_includes @report.errors[:report_type], "is not included in the list"
  end

  test "requires message and current path" do
    @report.message = ""
    @report.current_path = ""

    assert_not @report.valid?
    assert_includes @report.errors[:message], "can't be blank"
    assert_includes @report.errors[:current_path], "can't be blank"
  end

  test "requires role snapshot" do
    @report.role_keys = []

    assert_not @report.valid?
    assert_includes @report.errors[:role_keys], "can't be blank"
  end

end
