class TestUser < Marten::DB::Model
  field :id, :big_auto, primary_key: true
  field :username, :string, blank: false, null: false, max_size: 155, unique: true
  field :email, :string, blank: false, null: false, max_size: 254
  field :first_name, :string, blank: false, null: false, max_size: 150
  field :last_name, :string, blank: false, null: false, max_size: 150
  field :created_at, :date_time, auto_now_add: true
  field :updated_at, :date_time, auto_now: true
end
