json.extract! garden_entry, :id, :title, :entry_date, :body, :created_at, :updated_at
json.url garden_entry_url(garden_entry, format: :json)
