json.extract! user, :id, :name, :pin, :created_at, :updated_at
json.roles user.roles.order(:name) do |role|
  json.extract! role, :id, :key, :name
end
json.url user_url(user, format: :json)
