class TestUserProfile < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :user, :one_to_one, to: TestUser, related: :profile
  field :bio, :text, blank: true, null: true
end
