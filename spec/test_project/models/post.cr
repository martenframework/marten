class Post < Marten::Model
  field :id, :big_auto, primary_key: true
  field :author, :many_to_one, to: TestUser, related: :posts, on_delete: :cascade
  field :updated_by, :many_to_one, to: TestUser, null: true, blank: true, on_delete: :set_null
  field :title, :string, max_size: 128
  field :published, :bool, default: true

  db_table :posts
  db_unique_constraint :author_title, field_names: [:author, :title]
end
