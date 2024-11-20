json.extract! user, :id, :name, :pin, :admin, :created_at, :updated_at
json.url user_url(user, format: :json)
