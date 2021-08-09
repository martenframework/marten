class Post < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :author, :many_to_one, to: TestUser, related: :posts, on_delete: :cascade
  field :updated_by, :many_to_one, to: TestUser, null: true, blank: true, on_delete: :set_null
  field :title, :string, max_size: 128
  field :published, :bool, default: true
  field :score, :float, null: true, blank: true

  db_table :posts
  db_index :author_title_index, field_names: [:author, :title]
  db_unique_constraint :author_title_constraint, field_names: [:author, :title]
end
