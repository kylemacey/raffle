class HealthController < ApplicationController
  skip_before_action :require_basic_auth
  skip_before_action :set_current_user

  def show
    ActiveRecord::Base.connection.select_value("SELECT 1")

    render json: { status: "ok" }, status: :ok
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.warn("Health check failed: #{e.class}: #{e.message}")
    render json: { status: "error" }, status: :service_unavailable
  end
end
