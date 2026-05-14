require "test_helper"

class HealthControllerTest < ActionDispatch::IntegrationTest
  test "show returns ok without authentication" do
    get up_url

    assert_response :success
    assert_nil response.redirect_url
    assert_equal({ "status" => "ok" }, JSON.parse(response.body))
  end

  test "show returns service unavailable when database check fails" do
    connection = ActiveRecord::Base.connection
    connection_singleton = class << connection; self; end
    original_select_value = connection.method(:select_value)

    connection_singleton.define_method(:select_value) do |_sql|
      raise ActiveRecord::ConnectionNotEstablished, "database unavailable"
    end

    begin
      get up_url
    ensure
      connection_singleton.define_method(:select_value) do |*args, &block|
        original_select_value.call(*args, &block)
      end
    end

    assert_response :service_unavailable
    assert_nil response.redirect_url
    assert_equal({ "status" => "error" }, JSON.parse(response.body))
  end
end
