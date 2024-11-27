# I guess Heroku uses self-signed SSL certificates

require 'redis'

Redis.current = Redis.new(
  url: ENV['REDIS_URL'], # Or your Redis URL
  ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
)