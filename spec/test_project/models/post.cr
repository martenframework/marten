class Post < Marten::DB::Model
  field :id, :auto, primary_key: true
  field :author, :foreign_key, to: TestUser
  field :updated_by, :foreign_key, to: TestUser, null: true, blank: true
  field :title, :string, max_size: 128
end
