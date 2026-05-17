class ApiTokensController < ApplicationController
  before_action -> { require_permission!("api_tokens.manage") }
  before_action :set_api_token, only: %i[show destroy]

  def index
    @api_tokens = ApiToken.includes(:created_by).ordered
  end

  def show
  end

  def new
    @api_token = ApiToken.new
    @expiration_option = ApiToken::DEFAULT_EXPIRATION_OPTION
  end

  def create
    @expiration_option = expiration_option
    @api_token, @plain_token = ApiToken.create_with_generated_token!(
      api_token_params.merge(
        created_by: current_user,
        expires_at: ApiToken.expires_at_for(@expiration_option)
      )
    )

    render :show, status: :created
  rescue ActiveRecord::RecordInvalid => error
    @api_token = error.record
    render :new, status: :unprocessable_entity
  end

  def destroy
    @api_token.destroy
    redirect_to api_tokens_url, notice: "API token was deleted."
  end

  private

  def set_api_token
    @api_token = ApiToken.find(params[:id])
  end

  def api_token_params
    params.require(:api_token).permit(:name)
  end

  def expiration_option
    option = params.dig(:api_token, :expiration_option)
    return option if ApiToken.expiration_options.key?(option)

    ApiToken::DEFAULT_EXPIRATION_OPTION
  end
end
