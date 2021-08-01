class ProtectedPost < Marten::Model
  field :id, :int, primary_key: true, auto: true
  field :post, :many_to_one, to: Post, on_delete: :protect
end
