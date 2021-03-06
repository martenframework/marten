class PostTags < Marten::DB::Model
  field :id, :big_auto, primary_key: true
  field :post, :one_to_many, to: Post, on_delete: :cascade
  field :tag, :one_to_many, to: Tag, on_delete: :cascade
end
