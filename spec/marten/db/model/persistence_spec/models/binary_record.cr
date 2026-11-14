class BinaryRecord < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :payload, :binary, default: Bytes[1, 2, 3]
  field :optional_payload, :binary, null: true, blank: true
end
