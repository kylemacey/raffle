class ApplicationController < ActionController::Base
  include AuthenticationHelper

  http_basic_authenticate_with name: 'kyle', password: 'thomas18'
end
