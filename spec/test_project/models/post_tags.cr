class PostTags < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :post, :many_to_one, to: Post, on_delete: :cascade
  field :tag, :many_to_one, to: Tag, on_delete: :cascade
end
