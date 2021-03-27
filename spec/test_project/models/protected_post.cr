class ProtectedPost < Marten::Model
  field :id, :auto, primary_key: true
  field :post, :many_to_one, to: Post, on_delete: :protect
end
