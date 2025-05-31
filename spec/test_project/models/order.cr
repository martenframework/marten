class Order < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :products, :many_to_many, to: Product, related: :orders

  with_timestamp_fields
end
