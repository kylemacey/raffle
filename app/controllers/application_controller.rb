class ApplicationController < ActionController::Base
  include AuthenticationHelper

  if Rails.env.production?
    http_name, http_password = ENV['HTTP_AUTH'].split(':')
    http_basic_authenticate_with name: http_name, password: http_password
  end
end
