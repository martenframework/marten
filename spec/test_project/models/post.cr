class Post < Marten::DB::Model
  field :id, :auto, primary_key: true
  field :author, :foreign_key, to: TestUser
  field :title, :string, max_size: 128
end
