json.extract! entry, :id, :name, :phone, :qty, :event_id, :created_at, :updated_at
json.url entry_url(entry, format: :json)
