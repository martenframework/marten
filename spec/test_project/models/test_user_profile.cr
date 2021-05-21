class TestUserProfile < Marten::Model
  field :id, :big_auto, primary_key: true
  field :user, :one_to_one, to: TestUser, related: :profile
end
