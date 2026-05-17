require "test_helper"

class ApiTokensControllerTest < ActionDispatch::IntegrationTest
  setup do
    @api_token = api_tokens(:ops)
    @admin = users(:admin)
    sign_in(@admin)
  end

  test "platform admin can list api tokens" do
    get api_tokens_url
    assert_response :success
    assert_select "h1", "API Tokens"
    assert_select "td", text: @api_token.name
  end

  test "config admin can manage api tokens" do
    config_admin = User.create!(name: "Config Admin", pin: "6677")
    config_admin.roles << roles(:config_admin)
    sign_in(config_admin)

    get api_tokens_url
    assert_response :success

    assert_difference("ApiToken.count") do
      post api_tokens_url, params: {
        api_token: {
          name: "Config admin token",
          expiration_option: "never"
        }
      }
    end

    assert_response :created
    assert_includes response.body, "Copy this token now"
    assert_nil ApiToken.last.expires_at
  end

  test "lower permission user cannot list api tokens" do
    sign_in(users(:one))

    get api_tokens_url
    assert_redirected_to pos_main_url
  end

  test "creates api token and shows plaintext once" do
    assert_difference("ApiToken.count") do
      post api_tokens_url, params: {
        api_token: {
          name: "One-time display token",
          expiration_option: "30_days"
        }
      }
    end

    api_token = ApiToken.last

    assert_response :created
    assert_includes response.body, "Copy this token now"
    plain_token = response.body.match(/raffle_[A-Za-z0-9_-]+/)[0]
    assert_in_delta 30.days.from_now.to_i, api_token.expires_at.to_i, 2

    get api_token_url(api_token)

    assert_response :success
    assert_not_includes response.body, plain_token
    assert_includes response.body, api_token.masked_token
  end

  test "does not create invalid api token" do
    assert_no_difference("ApiToken.count") do
      post api_tokens_url, params: {
        api_token: {
          name: "",
          expiration_option: "90_days"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "deletes api token" do
    assert_difference("ApiToken.count", -1) do
      delete api_token_url(@api_token)
    end

    assert_redirected_to api_tokens_url
  end
end
