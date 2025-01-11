module Marten::DB::Field::ManyToManySpec
  class UserRole < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :user, :many_to_one, to: Marten::DB::Field::ManyToManySpec::User, related: :user_roles
    field :role, :many_to_one, to: Marten::DB::Field::ManyToManySpec::Role, related: :user_roles
  end
end
