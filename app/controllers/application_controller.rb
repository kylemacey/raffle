class ApplicationController < ActionController::Base
  include AuthenticationHelper

  before_action :require_basic_auth
  before_action :set_current_user

  private

  def require_basic_auth
    if Rails.env.production? && !@skip_basic_auth
      http_name, http_password = ENV['HTTP_AUTH'].split(':')
      http_basic_authenticate_or_request_with name: http_name, password: http_password
    end
  end
end
