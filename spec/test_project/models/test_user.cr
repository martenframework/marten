class TestUser < Marten::Model
  field :id, :big_int, primary_key: true, auto: true

  field :username, :string, blank: false, null: false, max_size: 155, unique: true
  field :email, :string, blank: false, null: false, max_size: 254, index: true

  field :first_name, :string, blank: false, null: false, max_size: 150
  field :last_name, :string, blank: false, null: false, max_size: 150

  field :tags, :many_to_many, to: Tag, related: :test_users

  field :is_admin, :bool, null: true, default: false, blank: true

  field :created_at, :date_time, auto_now_add: true
  field :updated_at, :date_time, auto_now: true
end
