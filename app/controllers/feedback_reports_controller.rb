class FeedbackReportsController < ApplicationController
  before_action :require_authentication!
  before_action :require_internal_operator!, only: [:create]
  before_action -> { require_permission!("feedback_reports.view") }, only: [:index, :show]
  before_action :set_feedback_report, only: [:show]

  def index
    @feedback_reports = FeedbackReport.includes(user: :roles).order(created_at: :desc)
  end

  def show
  end

  def create
    @feedback_report = current_user.feedback_reports.build(feedback_report_params)
    @feedback_report.assign_attributes(request_context_attributes)

    respond_to do |format|
      if @feedback_report.save
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "feedback_report_form",
            partial: "feedback_reports/success"
          )
        end
        format.html { redirect_back fallback_location: default_after_sign_in_path, notice: "Report sent." }
        format.json { render json: { id: @feedback_report.id }, status: :created }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "feedback_report_form",
            partial: "feedback_reports/form",
            locals: { feedback_report: @feedback_report }
          ), status: :unprocessable_entity
        end
        format.html { redirect_back fallback_location: default_after_sign_in_path, alert: "Report could not be sent." }
        format.json { render json: @feedback_report.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_feedback_report
    @feedback_report = FeedbackReport.includes(user: :roles).find(params[:id])
  end

  def require_internal_operator!
    return true if current_user&.internal_operator?

    respond_to do |format|
      format.html { redirect_to default_authorization_failure_path, alert: "Not authorized" }
      format.turbo_stream { head :forbidden }
      format.json { head :forbidden }
    end
    false
  end

  def feedback_report_params
    params.require(:feedback_report).permit(
      :report_type,
      :message,
      :current_path,
      browser_metadata: {}
    )
  end

  def request_context_attributes
    {
      user_name: current_user.name,
      role_keys: current_user.role_keys.sort,
      referrer: request.referrer,
      user_agent: request.user_agent,
      remote_ip: request.remote_ip
    }
  end
end
