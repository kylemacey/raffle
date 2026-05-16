require "test_helper"

class FeedbackReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @feedback_report = FeedbackReport.create!(
      user: users(:one),
      user_name: users(:one).name,
      role_keys: ["cashier"],
      report_type: "bug",
      message: "Checkout button did not respond.",
      current_path: "/pos/main",
      referrer: "http://www.example.com/pos/main",
      user_agent: "System test browser",
      remote_ip: "127.0.0.1",
      browser_metadata: {
        "url" => "http://www.example.com/pos/main",
        "viewport_width" => "1200",
        "timezone" => "America/New_York"
      }
    )
  end

  test "platform admin can view feedback reports index" do
    sign_in(users(:admin))

    get feedback_reports_url

    assert_response :success
    assert_select "h1", "Feedback"
    assert_includes response.body, @feedback_report.message
    assert_includes response.body, users(:one).name
  end

  test "config admin can view feedback reports index" do
    config_admin = User.create!(name: "Config Admin", pin: "6677")
    config_admin.roles << roles(:config_admin)
    sign_in(config_admin)

    get feedback_reports_url

    assert_response :success
    assert_includes response.body, @feedback_report.message
  end

  test "event lead cannot view feedback reports index" do
    sign_in(users(:two))

    get feedback_reports_url

    assert_redirected_to pos_main_url
  end

  test "platform admin can view feedback report details" do
    sign_in(users(:admin))

    get feedback_report_url(@feedback_report)

    assert_response :success
    assert_select "h1", "Feedback ##{@feedback_report.id}"
    assert_includes response.body, @feedback_report.message
    assert_includes response.body, @feedback_report.user_agent
    assert_includes response.body, "America/New_York"
  end

  test "internal user creates report with request and browser context" do
    sign_in(users(:one))

    assert_difference("FeedbackReport.count") do
      post feedback_reports_url(format: :json),
           params: {
             feedback_report: {
               report_type: "bug",
               message: "Cart total was wrong.",
               current_path: "/pos/main",
               browser_metadata: {
                 url: "http://www.example.com/pos/main",
                 viewport_width: "1200",
                 timezone: "America/New_York"
               }
             }
           },
           headers: {
             "HTTP_USER_AGENT" => "System test browser",
             "HTTP_REFERER" => "http://www.example.com/pos/main"
           }
    end

    assert_response :created
    report = FeedbackReport.last
    assert_equal users(:one), report.user
    assert_equal users(:one).name, report.user_name
    assert_equal ["cashier"], report.role_keys
    assert_equal "bug", report.report_type
    assert_equal "Cart total was wrong.", report.message
    assert_equal "/pos/main", report.current_path
    assert_equal "System test browser", report.user_agent
    assert_equal "http://www.example.com/pos/main", report.referrer
    assert report.remote_ip.present?
    assert_equal "1200", report.browser_metadata["viewport_width"]
    assert_equal "America/New_York", report.browser_metadata["timezone"]
  end

  test "each internal persona can create a report" do
    role_keys = %w[cashier event_lead config_admin platform_admin board_reporter]

    role_keys.each_with_index do |role_key, index|
      user = User.create!(name: "#{role_key} user", pin: "55#{index}#{index}")
      user.roles << roles(role_key.to_sym)
      sign_in(user)

      assert_difference("FeedbackReport.count") do
        post feedback_reports_url(format: :json), params: {
          feedback_report: {
            report_type: "feedback",
            message: "Reporting as #{role_key}.",
            current_path: "/events"
          }
        }
      end

      assert_response :created
      assert_equal [role_key], FeedbackReport.last.role_keys
    end
  end

  test "unauthenticated request is rejected" do
    assert_no_difference("FeedbackReport.count") do
      post feedback_reports_url, params: {
        feedback_report: {
          report_type: "bug",
          message: "No session.",
          current_path: "/events"
        }
      }
    end

    assert_redirected_to sign_in_path
  end

  test "authenticated user without internal role is rejected" do
    user = User.create!(name: "No Role", pin: "9090")
    sign_in(user)

    assert_no_difference("FeedbackReport.count") do
      post feedback_reports_url(format: :json), params: {
        feedback_report: {
          report_type: "bug",
          message: "No role.",
          current_path: "/events"
        }
      }
    end

    assert_response :forbidden
  end

  test "invalid submission returns errors and does not persist" do
    sign_in(users(:one))

    assert_no_difference("FeedbackReport.count") do
      post feedback_reports_url(format: :json), params: {
        feedback_report: {
          report_type: "bug",
          message: "",
          current_path: "/pos/main"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes JSON.parse(response.body)["message"], "can't be blank"
  end

  test "invalid turbo stream submission preserves feedback frame target" do
    sign_in(users(:one))

    assert_no_difference("FeedbackReport.count") do
      post feedback_reports_url,
           params: {
             feedback_report: {
               report_type: "bug",
               message: "",
               current_path: "/pos/main"
             }
           },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :unprocessable_entity
    assert_select "turbo-stream[action='update'][target='feedback_report_form']"
    assert_includes response.body, "Report could not be sent."
  end

  test "valid turbo stream submission preserves feedback frame target" do
    sign_in(users(:one))

    assert_difference("FeedbackReport.count") do
      post feedback_reports_url,
           params: {
             feedback_report: {
               report_type: "bug",
               message: "Retry worked.",
               current_path: "/pos/main"
             }
           },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :success
    assert_select "turbo-stream[action='update'][target='feedback_report_form']"
    assert_includes response.body, "Report sent."
  end
end
