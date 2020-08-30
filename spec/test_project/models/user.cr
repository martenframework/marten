class User < Marten::DB::Model
  field :id, :big_auto, primary_key: true
  field :username, :string, blank: false, null: false, name: "", max_size: 155
  field :email, :string, blank: false, null: false, name: "", max_size: 254
  field :first_name, :string, blank: false, null: false, name: "", max_size: 150
  field :last_name, :string, blank: false, null: false, name: "", max_size: 150
end
