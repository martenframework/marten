class Product < Marten::Model
  field :sku, :string, max_size: 20, primary_key: true, unique: true
  field :name, :string, max_size: 255
  field :price_cents, :big_int, null: false

  with_timestamp_fields
end
