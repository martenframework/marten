class Post < Marten::DB::Model
  field :id, :big_auto, primary_key: true
  field :author, :one_to_many, to: TestUser, on_delete: :cascade
  field :updated_by, :one_to_many, to: TestUser, null: true, blank: true, on_delete: :set_null
  field :title, :string, max_size: 128
end
