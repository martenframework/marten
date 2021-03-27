class PostTags < Marten::Model
  field :id, :big_auto, primary_key: true
  field :post, :many_to_one, to: Post, on_delete: :cascade
  field :tag, :many_to_one, to: Tag, on_delete: :cascade
end
