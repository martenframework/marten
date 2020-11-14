class Post < Marten::DB::Model
  field :id, :auto, primary_key: true
  field :author, :one_to_many, to: TestUser
  field :updated_by, :one_to_many, to: TestUser, null: true, blank: true
  field :title, :string, max_size: 128
end
