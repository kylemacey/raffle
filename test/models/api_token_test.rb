require "test_helper"

class ApiTokenTest < ActiveSupport::TestCase
  setup do
    @admin = users(:admin)
  end

  test "creates token while storing only digest and display metadata" do
    api_token, plain_token = ApiToken.create_with_generated_token!(
      name: "Ops automation",
      created_by: @admin,
      expires_at: ApiToken.expires_at_for("30_days")
    )

    assert_match(/\Araffle_/, plain_token)
    assert_equal ApiToken.digest_token(plain_token), api_token.token_digest
    assert_not_equal plain_token, api_token.token_digest
    assert_equal plain_token.first(ApiToken::TOKEN_PREFIX_LENGTH), api_token.token_prefix
    assert_equal plain_token.last(ApiToken::TOKEN_LAST_FOUR_LENGTH), api_token.token_last_four
    refute_includes api_token.attributes.values, plain_token
  end

  test "calculates expiration options" do
    assert_in_delta 30.days.from_now.to_i, ApiToken.expires_at_for("30_days").to_i, 2
    assert_in_delta 90.days.from_now.to_i, ApiToken.expires_at_for("90_days").to_i, 2
    assert_in_delta 1.year.from_now.to_i, ApiToken.expires_at_for("1_year").to_i, 2
    assert_nil ApiToken.expires_at_for("never")
  end

  test "defaults unknown expiration option to ninety days" do
    assert_in_delta 90.days.from_now.to_i, ApiToken.expires_at_for("bogus").to_i, 2
  end

  test "rejects blank names" do
    assert_raises(ActiveRecord::RecordInvalid) do
      ApiToken.create_with_generated_token!(name: "", created_by: @admin)
    end
  end

  test "retries generated digest collisions" do
    duplicate_token = "raffle_duplicate_token"
    unique_token = "raffle_unique_token"

    ApiToken.create_with_generated_token!(
      name: "Existing",
      created_by: @admin,
      expires_at: nil
    ).first.update!(ApiToken.token_attributes(duplicate_token))

    generated_tokens = [duplicate_token, unique_token]

    ApiToken.singleton_class.alias_method :generate_token_without_test_stub, :generate_token
    ApiToken.define_singleton_method(:generate_token) { generated_tokens.shift }

    begin
      api_token, plain_token = ApiToken.create_with_generated_token!(
        name: "Retried",
        created_by: @admin,
        expires_at: nil
      )

      assert_equal unique_token, plain_token
      assert_equal ApiToken.digest_token(unique_token), api_token.token_digest
    ensure
      ApiToken.singleton_class.alias_method :generate_token, :generate_token_without_test_stub
      ApiToken.singleton_class.remove_method :generate_token_without_test_stub
    end
  end

  test "reports active and expired state" do
    active = api_tokens(:ops)
    expired = ApiToken.create_with_generated_token!(
      name: "Expired",
      created_by: @admin,
      expires_at: 1.minute.ago
    ).first

    assert active.active?
    assert_not active.expired?
    assert expired.expired?
    assert_not expired.active?
  end
end
