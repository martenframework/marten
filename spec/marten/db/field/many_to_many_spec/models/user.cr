module Marten::DB::Field::ManyToManySpec
  class User < Marten::Model
    field :id, :big_int, primary_key: true, auto: true
    field :name, :string, max_size: 255
    field :roles, :many_to_many,
      to: Marten::DB::Field::ManyToManySpec::Role,
      through: Marten::DB::Field::ManyToManySpec::UserRole
  end
end
